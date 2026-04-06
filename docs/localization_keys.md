# Localization keys audit (Phase 1 baseline)

## Scope and counts

- Scan scope: `Sources/Presentation/Views/**/*.swift` + presentation text in `Sources/Domain/Models/Session.swift`
- Regex passes used: `Text("...")`, `Button("...")`, `.alert("...")`, `TextField("...")`, and string literals returned from presentation helper functions.
- Total mapped localization keys identified: **74**
  - Presentation Views / shared UI keys: **71**
  - Domain-originated presentation text (`Session.rating`): **3**

## Key mapping

| Suggested key | English text (baseline literal) | Source file |
|---|---|---|
| dashboard.header.brand.charger | Charger | Sources/Presentation/Views/DashboardView.swift |
| dashboard.header.brand.monitor | Monitor | Sources/Presentation/Views/DashboardView.swift |
| dashboard.header.subtitle | Apple M-series · macOS Battery Telemetry | Sources/Presentation/Views/DashboardView.swift |
| dashboard.status.live_stream | Live Stream | Sources/Presentation/Views/DashboardView.swift |
| dashboard.status.connecting | Connecting... | Sources/Presentation/Views/DashboardView.swift |
| dashboard.status.no_connection | No Connection | Sources/Presentation/Views/DashboardView.swift |
| dashboard.metrics.power.label | Power | Sources/Presentation/Views/DashboardView.swift |
| dashboard.metrics.voltage.label | Voltage | Sources/Presentation/Views/DashboardView.swift |
| dashboard.metrics.current.label | Current | Sources/Presentation/Views/DashboardView.swift |
| dashboard.metrics.temperature.label | Temperature | Sources/Presentation/Views/DashboardView.swift |
| dashboard.metrics.voltage.subtitle.power_connected | Power connected | Sources/Presentation/Views/DashboardView.swift |
| dashboard.metrics.voltage.subtitle.on_battery | On battery | Sources/Presentation/Views/DashboardView.swift |
| dashboard.metrics.current.subtitle.into_battery | ↑ into battery | Sources/Presentation/Views/DashboardView.swift |
| dashboard.metrics.current.subtitle.from_battery | ↓ from battery | Sources/Presentation/Views/DashboardView.swift |
| dashboard.metrics.power.subtitle.waiting_data | waiting for data | Sources/Presentation/Views/DashboardView.swift |
| dashboard.metrics.power.subtitle.charging_adapter_format | Charging · adapter %@ | Sources/Presentation/Views/DashboardView.swift |
| dashboard.metrics.power.subtitle.discharge_battery | Discharge · on battery | Sources/Presentation/Views/DashboardView.swift |
| dashboard.metrics.power.subtitle.connected_full | Connected · full charge | Sources/Presentation/Views/DashboardView.swift |
| dashboard.metrics.temperature.subtitle.hot | Hot | Sources/Presentation/Views/DashboardView.swift |
| dashboard.metrics.temperature.subtitle.warm | Warm | Sources/Presentation/Views/DashboardView.swift |
| dashboard.metrics.temperature.subtitle.normal | Normal | Sources/Presentation/Views/DashboardView.swift |
| dashboard.footer.data_source | Data via ioreg AppleSmartBattery · Updates every 2s · Data from Mac only, not from charger | Sources/Presentation/Views/DashboardView.swift |
| battery.card.title | BATTERY | Sources/Presentation/Views/BatteryCardView.swift |
| battery.card.status.fully_charged | Fully Charged | Sources/Presentation/Views/BatteryCardView.swift |
| battery.card.status.charging | Charging | Sources/Presentation/Views/BatteryCardView.swift |
| battery.card.status.plugged_in | Plugged In | Sources/Presentation/Views/BatteryCardView.swift |
| battery.card.status.discharging | Discharging | Sources/Presentation/Views/BatteryCardView.swift |
| battery.card.capacity.format | %d / %d mAh | Sources/Presentation/Views/BatteryCardView.swift |
| battery.card.capacity.unknown | — mAh | Sources/Presentation/Views/BatteryCardView.swift |
| battery.card.time.full | Full | Sources/Presentation/Views/BatteryCardView.swift |
| battery.card.time.pending | ... | Sources/Presentation/Views/BatteryCardView.swift |
| battery.card.time.hours_minutes.format | %dh %dm | Sources/Presentation/Views/BatteryCardView.swift |
| battery.card.time.minutes.format | %dm | Sources/Presentation/Views/BatteryCardView.swift |
| battery.health.title | BATTERY HEALTH | Sources/Presentation/Views/BatteryHealthView.swift |
| battery.health.row.health | Health | Sources/Presentation/Views/BatteryHealthView.swift |
| battery.health.row.cycles | Cycles | Sources/Presentation/Views/BatteryHealthView.swift |
| battery.health.row.max_capacity | Max Capacity | Sources/Presentation/Views/BatteryHealthView.swift |
| battery.health.row.design_capacity | Design Capacity | Sources/Presentation/Views/BatteryHealthView.swift |
| battery.health.row.adapter | Adapter | Sources/Presentation/Views/BatteryHealthView.swift |
| battery.health.row.plugged_in | Plugged In | Sources/Presentation/Views/BatteryHealthView.swift |
| power.chart.title | POWER HISTORY (LAST 5 MIN) | Sources/Presentation/Views/PowerChartView.swift |
| power.chart.legend.charging | Charging (W) | Sources/Presentation/Views/PowerChartView.swift |
| power.chart.legend.discharge | Discharge (W) | Sources/Presentation/Views/PowerChartView.swift |
| sessions.title | CHARGER COMPARISON | Sources/Presentation/Views/SessionsComparisonView.swift |
| sessions.subtitle | Plug charger → record session → switch → repeat | Sources/Presentation/Views/SessionsComparisonView.swift |
| sessions.button.stop | Stop | Sources/Presentation/Views/SessionsComparisonView.swift |
| sessions.button.record | Record Session | Sources/Presentation/Views/SessionsComparisonView.swift |
| sessions.button.clear | Clear | Sources/Presentation/Views/SessionsComparisonView.swift |
| sessions.alert.title | Session Name | Sources/Presentation/Views/SessionsComparisonView.swift |
| sessions.alert.textfield.placeholder | Charger name | Sources/Presentation/Views/SessionsComparisonView.swift |
| sessions.alert.button.start | Start | Sources/Presentation/Views/SessionsComparisonView.swift |
| sessions.alert.message | Enter a name for this charging session | Sources/Presentation/Views/SessionsComparisonView.swift |
| sessions.recording | Recording | Sources/Presentation/Views/SessionsComparisonView.swift |
| sessions.empty.title | No recorded sessions. | Sources/Presentation/Views/SessionsComparisonView.swift |
| sessions.empty.subtitle | Plug in a charger and press "Record Session". | Sources/Presentation/Views/SessionsComparisonView.swift |
| sessions.badge.best | BEST | Sources/Presentation/Views/SessionsComparisonView.swift |
| sessions.table.header.charger | Charger | Sources/Presentation/Views/SessionsComparisonView.swift |
| sessions.table.header.duration | Duration | Sources/Presentation/Views/SessionsComparisonView.swift |
| sessions.table.header.peak_w | Peak W | Sources/Presentation/Views/SessionsComparisonView.swift |
| sessions.table.header.avg_w | Avg W | Sources/Presentation/Views/SessionsComparisonView.swift |
| sessions.table.header.delta_charge | +% Charge | Sources/Presentation/Views/SessionsComparisonView.swift |
| sessions.table.header.avg_temp | Avg Temp | Sources/Presentation/Views/SessionsComparisonView.swift |
| sessions.table.header.rating | Rating | Sources/Presentation/Views/SessionsComparisonView.swift |
| sessions.session.fallback_name | Session | Sources/Presentation/Views/SessionsComparisonView.swift |
| sessions.default_name.format | Charger %d | Sources/Presentation/Views/SessionsComparisonView.swift |
| sessions.duration.minutes_seconds.format | %dm %ds | Sources/Presentation/Views/SessionsComparisonView.swift |
| sessions.duration.seconds.format | %ds | Sources/Presentation/Views/SessionsComparisonView.swift |
| session.rating.excellent | Excellent | Sources/Domain/Models/Session.swift |
| session.rating.good | Good | Sources/Domain/Models/Session.swift |
| session.rating.fair | Weak | Sources/Domain/Models/Session.swift |
| settings.poll_interval | Poll interval | Sources/Presentation/Views/SettingsView.swift |
| common.value.unknown | — | Shared (multiple Views + Domain fallback text) |
| common.answer.yes | Yes | Sources/Presentation/Views/BatteryHealthView.swift |
| common.answer.no | No | Sources/Presentation/Views/BatteryHealthView.swift |

## Notes

- Existing localization keys in `Resources/*/Localizable.strings` were reused where applicable (`app.title`, `settings.*`, `btn.*`, `theme.*`).
- `Session.rating` is represented as a domain enum in Phase 1; localized labels are now provided in Presentation via `session.rating.*` keys.
