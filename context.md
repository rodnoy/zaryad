# Проект: Charger Monitor — контекст

Дата: 2026-04-03

## Files Retrieved
1. `charger_dashboard.html` (lines 1-872) - Полный статический фронтенд (HTML/CSS/JS). Интерфейс, рендеринг графика, логика записи сессий, получение данных через `/data.json`.
2. `charger_server.sh` (lines 1-176) - Запускной скрипт: собирает данные с macOS (system_profiler + ioreg) через встроенный Python, пишет JSON в /tmp/charger_data.json и запускает простой HTTP-сервер для отдачи HTML и data.json на localhost:7823.

## Key Code

- Python-сборщик данных (встроен в charger_server.sh, функция collect_data):
  - Вызов system_profiler SPPowerDataType для получения: Full Charge Capacity (mAh), State of Charge (%), Cycle Count, Wattage (адаптера), Charging/Connected/Fully Charged.
  - Вызов `ioreg -rn AppleSmartBattery` и парсинг полей: Voltage, Amperage, DesignCapacity, MaxCapacity, Temperature, TimeRemaining.
  - Преобразование:
    - voltage_v = Voltage / 1000
    - amperage_a = Amperage / 1000
    - power_w = voltage_v * amperage_a (rounded)
    - temp_c = Temperature / 100
    - health_pct = MaxCapacity * 100 / DesignCapacity
  - Формирует JSON с полями: timestamp, voltage_v, amperage_a, power_w, temp_c, percent, health_pct, current_mah, max_mah, design_mah, cycle_count, is_charging, plugged_in, fully_charged, time_remaining_min, adapter_watts

- HTTP-сервер (встроен в charger_server.sh, Python):
  - Отдаёт `/` или `/index.html` → `charger_dashboard.html`
  - Отдаёт `/data.json` → файл с данными (в /tmp)
  - Без внешних зависимостей (http.server, socketserver)

- Фронтенд (charger_dashboard.html):
  - fetchData() — периодически (каждые 2s) запрашивает `/data.json?t=...`, парсит JSON, управляет статусом соединения/error-banner и вызывает updateUI(d).
  - updateUI(d) — обновляет все метрики на странице: мощность, напряжение, ток, температура, проценты, полосу батареи, инфо-поля (health, cycles, adapter, plugged), добавляет точку в chartData.power и вызывает drawChart(). Также дополняет активную запись сессии (если есть).
  - drawChart() — кастомный рендер на canvas: область заряда (>0) зелёная, разряда (<0) жёлтая, линия мощности. Поддерживает буфер до MAX_POINTS (~150, ~5 минут).
  - Сессии: startSession(), stopSession(), clearSessions(), renderSessions(). Сессии хранятся в localStorage (ключ 'charger_sessions'). При остановке сессии вычисляются: длительность, peakW, avgW (для charging powers >0), avgTemp, deltaPercent (разница процента батареи), рейтинг по avgW.
  - UI: error banner при отсутствии данных, статус-pill, карточки метрик, battery bar, таблица сравнений зарядников, кнопки для записи/очистки сессий.

## Architecture

Общая архитектура простая и однозадачная:

- Компоненты:
  1. Data Collector (скрипт в charger_server.sh → embedded Python)
     - Работает в фоне (цикл, каждые 2 секунды), вызывает system_profiler и ioreg, парсит значения и записывает JSON в /tmp/charger_data.json.
     - Запускается вместе с простым HTTP-сервером.
  2. HTTP Server (embedded Python в charger_server.sh)
     - Отдаёт статический HTML и текущий JSON по запросу.
  3. Frontend (charger_dashboard.html)
     - Одностраничный интерфейс: рендерит метрики, график, позволяет записывать сессии в localStorage.

- Поток данных:
  system_profiler / ioreg (macOS) → Python parser → /tmp/charger_data.json → HTTP GET /data.json → frontend fetchData() → updateUI()

- Периодичность:
  - Collector: пишет данные каждые ~2s
  - Frontend: опрашивает /data.json каждые 2s

- Хранилища:
  - Временные данные: /tmp/charger_data.json
  - Сессии/пользовательские данные: localStorage в браузере

## Бизнес-логика

Цель приложения — мониторить заряд/разряд MacBook (Apple M-series) и оценивать производительность/качество зарядников (адаптеров).

Ключевые сценарии:
- Наблюдение в реальном времени:
  - Показ текущей мощности (W), напряжения (V), тока (A), температуры (°C), % батареи, статус зарядки/подключения.
  - Визуализация последних ~5 минут мощности (график). Позволяет видеть пики заряда/разряда.
- Запись сессий для сравнения зарядников:
  - Пользователь нажимает «Записать сессию», подключает зарядник, скрипт собирает массивы мощности и температуры пока идёт запись.
  - По завершении сессии вычисляется: длительность, пик мощности, средняя мощность (только положительные значения — зарядка), изменение % батареи, средняя температура, простая оценка качества.
  - Сессии хранятся локально в браузере; отображаются в таблице и помечается лучшая по avgW.
- Обработка ошибок/UX:
  - При отсутствии сервера показывается баннер с инструкцией запускать charger_server.sh.
  - Индикатор статуса соединения (dot + текст).

Ограничения/Особенности:
- Данные берутся только с macOS через system_profiler и ioreg — подходит только для Mac, не получает данные непосредственно от зарядника (подчеркивается в футере).
- Рассчёт мощности прост: voltage * amperage (на данных из ioreg), возможны шумы/погрешности.
- Логика сравнения зарядников простая и эмпирическая (avgW, peakW, delta% заряда).

## Основные экраны / UI-блоки

1. Хедер: логотип, статус подключения
2. Большой ряд метрик (4 колонки): Мощность, Напряжение, Ток, Темп.
3. График мощности (последние ~5 мин)
4. Карточка батареи: процент, статус заряда, визуальная полоса, емкость и время
5. Карточка состояния батареи: Health%, Cycles, Max & Design capacity, Adapter Watts, Plugged
6. Сравнение сессий (запись/стоп/очистка): таблица с результатами и рейтингом
7. Error banner с инструкциями запуска сервера

## Внешние зависимости

- Требования на хосте (macOS):
  - system_profiler (входит в macOS)
  - ioreg (входит в macOS)
  - Python3 (для парсера + HTTP сервера)
  - Bash
  - Браузер (рекомендуется открыть по http://localhost:7823, не как файл)
- Никаких JS/CSS внешних библиотек, за исключением Google Fonts, подключённых через @import в CSS (JetBrains Mono, Space Grotesk).

## Потенциальные улучшения / замечания

- Валидация/обработка ошибок парсинга ioreg/system_profiler — сейчас скрипт пытается и выходит при ошибке, но можно добавить логирование/детектирование отсутствующих прав.
- Более точный учёт направления тока и знаков (ампераж может быть отрицательным в ioreg — фронтенд трактует >0 как зарядка)
- Возможность выгрузки/экспорта сессий (CSV/JSON) — сейчас хранится в localStorage
- Защита/безопасность: сервер слушает только localhost, но стоит отметить это явно.

## Start Here

Открыть и читать:
- `charger_dashboard.html` — UI и ключевая логика (fetchData, updateUI, drawChart, session management).
- `charger_server.sh` — как собираются данные (embedded Python collect_data) и как запускается сервер.

