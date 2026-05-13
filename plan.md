# Plan: macOS SwiftUI приложение — Zaryad

Дата: 2026-04-03

Goal
----
Создать macOS приложение на SwiftUI, повторяющее интерфейс и функционал `charger_dashboard.html` (реальное, нативное приложение). Приложение должно:
- Работать как на Intel, так и на Apple Silicon (универсальная сборка).
- Поддерживать macOS до версии 26.0 (Tahoe) включительно (и ниже — см. примечание о минимальном target).
- Использовать чистую архитектуру (Clean Architecture) с отдельными слоями Domain / Data / Presentation / App.
- При необходимости применять SwiftData (опционально, с fallback на Codable + файловое хранилище) для сессий.
- Собираться и запускаться вручную через Xcode (.xcodeproj доступен).

Plan (по шагам)
----------------
1. Подготовка репозитория
   - Сделать резервную копию текущих артефактов (context.md, charger_dashboard.html, charger_server.sh).
   - Создать топ-левел Xcode проект (.xcodeproj) и Swift Package (если нужен). Настроить scheme для Debug/Release.
   - Установить Deployment Target: macOS 13.0+ (можно понижать до 12.0, но Swift Charts / SwiftUI features рекомендуют 13+). Гарантировать совместимость вплоть до macOS 26.0.
   - Настроить универсальную сборку (ARCHS = arm64, x86_64) — в Xcode: "Any Mac (Apple Silicon, Intel)".

2. Архитектура проекта (файловая структура)
   - /Sources/App: App entry (AppDelegate/Scene), DI контейнер.
   - /Sources/Domain: модели (BatterySample, Session, Rating), use-cases (StartSession, StopSession, FetchRealtimeData, GetSessions).
   - /Sources/Data: репозитории (SystemPowerRepository, FileSessionStore, SwiftDataSessionStore), адаптеры для IOKit или shell-обёртки system_profiler/ioreg.
   - /Sources/Presentation: SwiftUI Views, ViewModels (ObservableObjects) с чистым сокращением логики (используют Domain use-cases).
   - /Resources/Assets & Localizations

3. Сбор данных о питании
   - Предпочтительный путь: нативные API (IOKit/IOPS/IORegistry) для получения Voltage, Amperage, Current Capacity, Design Capacity, Cycle Count, Temperature, State (charging/plugged). Это даёт стабильнее и без внешних зависимостей.
   - Fallback: выполнять `system_profiler SPPowerDataType` и `ioreg -rn AppleSmartBattery` через Process/Task и парсить вывод (когда нативный API не даёт нужных полей).
   - Реализовать SystemPowerRepository с async API: func fetchCurrentSample() async throws -> BatterySample.
   - Интервал: poll каждые 2 секунды (configurable).

4. Domain: модели и логика сессий
   - BatterySample: timestamp, voltageV, amperageA, powerW, tempC, percent, healthPct, currentMah, maxMah, designMah, cycleCount, isCharging, pluggedIn, fullyCharged, timeRemainingMin, adapterWatts.
   - Session: id, startTimestamp, endTimestamp?, samples: [BatterySample] или агрегаты (для экономии памяти), computed properties (duration, peakW, avgW, avgTemp, deltaPercent, rating).
   - UseCases: StartSessionUseCase, AppendSampleToSession, StopSessionUseCase (выполняет агрегации и рейтинг).

5. Persistence
   - Опция A (SwiftData): если среда поддержки SwiftData (macOS 14+ / Xcode соответствующий), хранить Session как @Model.
   - Опция B (Fallback): Codable → JSON файл в Application Support или в ~/Library/Application Support/<AppName>/sessions.json.
   - Интерфейс репозитория SessionStore протокол-ориентированный, DI для подмены в тестах.

6. Presentation / UI
   - Основные экраны:
     - DashboardView: status bar (connection), метрики (Power, Voltage, Current, Temp), BatteryCard (percent/status), PowerChart, Controls (Start/Stop session, Clear), SessionsSummary.
     - SessionsListView: таблица/список сессий, сортировка по avgW/peakW/duration, экспорт (CSV/JSON), удаление.
     - SettingsView: pollingInterval, useSwiftData toggle, adapter calibration, запустить встроенный сервер совместимости (опция для web dashboard).
   - Реализация графика:
     - Использовать Swift Charts (если доступно) или Canvas + Path для кастомного рендера, поддерживать цветовую индикацию charge (>0) / discharge (<0).
     - Буфер последних N точек (~150) по умолчанию.
   - ViewModels как ObservableObject: RealtimeViewModel (подписка на poller), SessionsViewModel (управление сохранением/загрузкой), SettingsViewModel.

7. Polling / Concurrency
   - Central Poller service (actor) выполняет fetchCurrentSample() по конфигурируемому таймеру (Task.sleep + async loop) и рассылает обновления через AsyncStream или Combine PassthroughSubject.
   - Presentation подписывается на поток, обновляет ViewModels.
   - При включённой Session запись: Poller отправляет сэмплы в SessionUseCase для агрегации.

8. Совместимость с существующим frontend
   - Опция: встроить режим "HTTP exporter", который запускает небольшой локальный HTTP-сервер (внутри приложения) отдающий /data.json и index.html (чтобы пользователи могли использовать старый веб-интерфейс). Реализовать как Toggle в Settings.

9. Tests & QA
   - Unit tests: Domain (агрегации сессий, рейтинг), Data (парсеры ioreg/system_profiler — мокировать вывод), Poller (timing), SessionStore.
   - UI tests: basic flows (start/stop session, render chart, sessions list).

10. Build / Release
   - Создать Xcode project (.xcodeproj) и инструкции для ручного запуска: открыть Xcode → выбрать target Mac (Any Mac) → Run.
   - Настроить GitHub Actions (opcional) для сборки универсальной релизной сборки (macOS runner) и упаковки .app/.pkg.

Files to Modify
----------------
- ./charger_dashboard.html — оставить как reference (опционально встроить в app resources for web-mode).
- ./charger_server.sh — опционально: добавить заметку, что приложение имеет встроенный exporter, и обновить/отключить старый скрипт.
- README.md — добавить инструкции по запуску нативного приложения, требования и build steps.

New Files (предлагаемые)
-------------------------
- /Zaryad.xcodeproj/  (Xcode project)
- /Sources/App/App.swift (App entry point)
- /Sources/App/DIContainer.swift
- /Sources/Domain/Models/BatterySample.swift
- /Sources/Domain/Models/Session.swift
- /Sources/Domain/UseCases/SessionUseCases.swift
- /Sources/Data/SystemPower/SystemPowerRepository.swift (IOKit + shell fallback)
- /Sources/Data/SessionStore/SwiftDataSessionStore.swift
- /Sources/Data/SessionStore/FileSessionStore.swift
- /Sources/Presentation/Views/DashboardView.swift
- /Sources/Presentation/Views/PowerChartView.swift
- /Sources/Presentation/ViewModels/RealtimeViewModel.swift
- /Resources/Assets.xcassets
- /Resources/charger_dashboard.html (optional, embedded copy)
- /README.md (updated with build/run instructions)

Risks и Mitигaции
------------------
- Парсинг system_profiler / ioreg ненадёжен и медленен: mitigatie — использовать нативные IOKit API; держать fallback, кэшировать результаты.
- Различия в значениях между ioreg и нативными API: добавить калибровочные настройки и показать источник данных в UI.
- SwiftData недоступен на старых macOS: сделать абстракцию SessionStore с fallback на Codable-file.
- Права/привилегии: часть информации может требовать прав — проверять поведение без прав и информировать пользователя.
- Производительность UI при частых обновлениях (2s): использовать диффинг/батчинг обновлений, ограничивать количество точек в графике (sliding window).
- Поддержка macOS 26.0: периодически проверять API-совместимость и тестировать на новейших бета/релиз сборках.

Deliverables
------------
- Созданный файл plan.md (текущий файл).
- Xcode project skeleton с наборами файлов, описанных выше.
- Working prototype App: Dashboard + polling + sessions storage + export.
- Документация: README с инструкциями по сборке и запуску на Intel / Apple Silicon.

Примечание
----------
Минимальный deployment target выбирается в зависимости от используемых API (Swift Charts, SwiftData). Если нужно поддержать очень старые macOS — можно понизить target и заменить недоступные фреймворки (Charts → Canvas, SwiftData → Codable store).

(Конец плана)
