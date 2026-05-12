#!/bin/bash
# ⚡ Zaryad
# Запуск: chmod +x zaryad_server.sh && ./zaryad_server.sh
# Браузер: http://localhost:7823

PORT=7823
DATA_FILE="/tmp/charger_data.json"
HTML_FILE="$(cd "$(dirname "$0")" && pwd)/charger_dashboard.html"

echo "⚡ Zaryad"
echo "   Открой в браузере: http://localhost:$PORT"
echo "   Ctrl+C для остановки"
echo ""

if [ ! -f "$HTML_FILE" ]; then
  echo "❌ Не найден charger_dashboard.html рядом со скриптом"
  exit 1
fi

# Весь сбор и парсинг делается в Python — никакого bash-ioreg
collect_data() {
python3 << 'PYEOF'
import subprocess, re, json

def run(cmd):
    try:
        return subprocess.check_output(cmd, shell=True, stderr=subprocess.DEVNULL, text=True)
    except:
        return ""

# --- system_profiler: надёжные поля ---
prof = run("system_profiler SPPowerDataType")

def sp(pattern, text, default=None):
    m = re.search(pattern, text, re.IGNORECASE)
    return m.group(1).strip() if m else default

full_cap_mah = int(sp(r'Full Charge Capacity \(mAh\):\s*(\d+)', prof) or 0)
state_pct     = float(sp(r'State of Charge \(%\):\s*([\d.]+)', prof) or 0)
cycle_count   = int(sp(r'Cycle Count:\s*(\d+)', prof) or 0)
adapter_w     = int(sp(r'Wattage \(W\):\s*(\d+)', prof) or 0)
charging_raw  = sp(r'^\s*Charging:\s*(Yes|No)', prof, 'No')
plugged_raw   = sp(r'Connected:\s*(Yes|No)', prof, 'No')
full_raw      = sp(r'Fully Charged:\s*(Yes|No)', prof, 'No')

def to_bool(v):
    return v.strip().lower() == 'yes' if v else False

is_charging  = to_bool(charging_raw)
plugged_in   = to_bool(plugged_raw)
fully_charged = to_bool(full_raw)

# --- ioreg: парсим строки вида "Key" = Value ---
# Используем grep чтобы взять только нужные строки (без вложенных блоков)
def ioreg_int(key):
    """Берёт строку вида   "Key" = 12345  и возвращает int"""
    raw = run(f'ioreg -rn AppleSmartBattery 2>/dev/null | grep \'"{ key }"\' ')
    # Ищем паттерн: "Key" = NUMBER (только число, не структуру)
    for line in raw.splitlines():
        m = re.search(r'"' + re.escape(key) + r'"\s*=\s*(-?\d+)', line)
        if m:
            return int(m.group(1))
    return None

voltage_mv  = ioreg_int('Voltage')
amperage_ma = ioreg_int('Amperage')
design_mah  = ioreg_int('DesignCapacity')
max_mah     = ioreg_int('MaxCapacity')
temp_raw    = ioreg_int('Temperature')
time_min    = ioreg_int('TimeRemaining')

voltage_v  = (voltage_mv  / 1000) if voltage_mv  is not None else 0.0
amperage_a = (amperage_ma / 1000) if amperage_ma is not None else 0.0
power_w    = round(voltage_v * amperage_a, 2)
temp_c     = round(temp_raw / 100, 1) if temp_raw is not None else 0.0

if max_mah and design_mah and design_mah > 0:
    health_pct = round(max_mah * 100 / design_mah, 1)
else:
    health_pct = 100.0

import datetime
timestamp = datetime.datetime.utcnow().strftime('%Y-%m-%dT%H:%M:%SZ')

d = {
    "timestamp":          timestamp,
    "voltage_v":          round(voltage_v, 3),
    "amperage_a":         round(amperage_a, 3),
    "power_w":            power_w,
    "temp_c":             temp_c,
    "percent":            state_pct,
    "health_pct":         health_pct,
    "current_mah":        full_cap_mah,
    "max_mah":            max_mah or 0,
    "design_mah":         design_mah or 0,
    "cycle_count":        cycle_count,
    "is_charging":        is_charging,
    "plugged_in":         plugged_in,
    "fully_charged":      fully_charged,
    "time_remaining_min": time_min or 0,
    "adapter_watts":      adapter_w,
}
print(json.dumps(d, indent=2))
PYEOF
}

# Тест
echo "Тест сбора данных..."
collect_data > "$DATA_FILE"
if python3 -c "import json; d=json.load(open('$DATA_FILE')); print('✓ OK:', d)" 2>/dev/null; then
    echo ""
else
    echo "❌ Ошибка парсинга:"
    cat "$DATA_FILE"
    exit 1
fi

# Фоновый сбор
(while true; do
    collect_data > "$DATA_FILE" 2>/dev/null
    sleep 2
done) &
COLLECTOR_PID=$!

cleanup() {
    echo "Останавливаю..."
    kill $COLLECTOR_PID 2>/dev/null
    exit 0
}
trap cleanup INT TERM

python3 - "$HTML_FILE" "$DATA_FILE" "$PORT" << 'PYEOF'
import sys, http.server, socketserver

HTML_FILE = sys.argv[1]
DATA_FILE = sys.argv[2]
PORT = int(sys.argv[3])

class Handler(http.server.BaseHTTPRequestHandler):
    def do_GET(self):
        path = self.path.split('?')[0]
        if path in ('/', '/index.html'):
            self.serve_file(HTML_FILE, 'text/html; charset=utf-8')
        elif path == '/data.json':
            self.serve_file(DATA_FILE, 'application/json')
        else:
            self.send_response(404)
            self.end_headers()

    def serve_file(self, filepath, content_type):
        try:
            with open(filepath, 'rb') as f:
                content = f.read()
            self.send_response(200)
            self.send_header('Content-Type', content_type)
            self.send_header('Content-Length', str(len(content)))
            self.send_header('Cache-Control', 'no-cache')
            self.end_headers()
            self.wfile.write(content)
        except Exception:
            self.send_response(500)
            self.end_headers()

    def log_message(self, *a): pass
    def handle_error(self, *a): pass

class Server(socketserver.TCPServer):
    allow_reuse_address = True
    def handle_error(self, *a): pass

print(f'Сервер запущен → http://localhost:{PORT}')
with Server(('localhost', PORT), Handler) as httpd:
    httpd.serve_forever()
PYEOF

wait $COLLECTOR_PID
