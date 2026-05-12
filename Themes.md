# Темы (Themes) — реализация в этом проекте (Zaryad)

Этот документ описывает, как темы реализованы в приложении Zaryad, как их переключать и обновлять, а также как добавить новую тему в проект.

Файлы, в которых реализована тема

- Sources/Presentation/Theme/Theme.swift
  - Описывает модель Theme и встроенные темы (dark, light, forest, marine, martian).
  - Theme содержит вложенную структуру Palette с набором Color-полей: bg, surface, surface2, border, accent, accent2, green, yellow, red, text, muted.
  - Есть статические свойства для каждой встроенной темы и метод forKey(_:) для получения темы по ключу.

- Sources/Presentation/Theme/ThemeStore.swift
  - ObservableObject (ThemeStore) с @Published var current: Theme.
  - Хранит список доступных тем: ThemeStore.all (в коде: [.dark, .light, .forest, .marine, .martian]).
  - При инициализации читает ключ выбранной темы из UserDefaults (ключ: "selectedTheme") и восстанавливает текущую тему.
  - Метод select(key:) переключает тему, обновляет current и сохраняет выбранный ключ в UserDefaults.

- Sources/Presentation/Theme/AppTheme.swift
  - Утилитарный набор computed-свойств, которые возвращают цвета/шрифты/паддинги/радиусы, основанные на палитре выбранной темы.
  - palette читается напрямую из UserDefaults: Theme.forKey(UserDefaults.standard.string(forKey: "selectedTheme") ?? Theme.dark.key).palette. Поэтому AppTheme возвращает актуальные значения, основанные на сохранённом ключе темы.
  - Содержит конструктор Color(hex:) для удобного создания цветов по hex-строке.
  - Включает helper-ы: batteryGradient(percent:), CardModifier/view extension .cardStyle() и др.

- Sources/Presentation/Views/SettingsView.swift
  - UI для выбора темы: Picker, который привязан к ThemeStore.currentKey и вызывает themeStore.select(key:).
  - При выборе тема сохраняется и применяется.

Где хранятся имена тем для UI

- Resources/*/.lproj/Localizable.strings
  - Локализованные строки с ключами theme.dark, theme.light, theme.forest, theme.marine, theme.martian.
  - SettingsView выводит Text(theme.displayNameKey), поэтому для корректного отображения добавьте переводы в нужные .lproj.

Как тема применяется и обновляется в runtime

1. Выбор темы через SettingsView вызывает ThemeStore.select(key:).
   - select(key:) устанавливает ThemeStore.current = Theme.forKey(key) и записывает ключ в UserDefaults под "selectedTheme".
2. AppTheme.* computed-свойства читают палитру по ключу из UserDefaults при каждом обращении.
   - Это означает, что при изменении ключа в UserDefaults последующие обращения к AppTheme будут возвращать новые цвета.
3. Views, которые используют @EnvironmentObject themeStore и подписаны на его @Published current, будут перерисованы автоматически при изменении ThemeStore.current.
4. Взаимодействие ThemeStore и AppTheme даёт гарантию: изменение через ThemeStore.select(...) сохранит ключ и вызовет обновление UI (через публикацию current + обращения AppTheme к UserDefaults).

Как поменять тему (пользовательские сценарии)

- Через UI: Откройте Settings → Theme (Picker) → выберите нужную тему. Picker вызывает themeStore.select(key:), тема сохраняется в UserDefaults и интерфейс обновится.
- Программно: Установите UserDefaults.standard.set("<themeKey>", forKey: "selectedTheme") и/или вызовите themeStore.select(key:). Рекомендуется вызывать themeStore.select(key:) чтобы обеспечить публикацию изменения.

Как добавить новую тему

Шаги (пошагово):

1) Добавьте описание темы в Theme.swift
   - Пример: добавим тему "solarized"

   // В Theme.swift (рядом с другими static let)
   public static let solarized = Theme(
       key: "solarized",
       displayNameKey: "theme.solarized",
       palette: Palette(
           bg: Color(hex: "fdf6e3"),
           surface: Color(hex: "fffef8"),
           surface2: Color(hex: "f2efe9"),
           border: Color(hex: "e3dcd2"),
           accent: Color(hex: "268bd2"),
           accent2: Color(hex: "2aa198"),
           green: Color(hex: "859900"),
           yellow: Color(hex: "b58900"),
           red: Color(hex: "dc322f"),
           text: Color(hex: "657b83"),
           muted: Color(hex: "93a1a1")
       )
   )

2) Зарегистрируйте тему в ThemeStore.all
   - Откройте ThemeStore.swift и добавьте вашу тему в статический список all, например:
     public static let all: [Theme] = [.dark, .light, .forest, .marine, .martian, .solarized]
   - Важно: ThemeStore.all — это статический let, поэтому изменение требует правки кода и пересборки приложения.

3) Добавьте строковые ресурсы для локализации
   - В Resources/ru.lproj/Localizable.strings (и другие .lproj при необходимости) добавьте:
     "theme.solarized" = "Solarized";
   - Это обеспечит отображение имени темы в SettingsView Picker.

4) (Опционально) Проверьте дизайн и контраст
   - Запустите приложение, выберите новую тему и пройдитесь по основным экранам: dashboard, карточки, графики, настройки.
   - Убедитесь, что текст читабелен (контраст), и элементы корректно окрашены (градиент батареи использует AppTheme.green/accent и т.д.).

5) (Опционально) Вынесение в отдельный модуль
   - Если хотите, можно вынести набор тем в отдельный Swift файл (или пакет) и импортировать его. Главное — убедиться, что ThemeStore.all содержит все доступные экземпляры Theme.

Как добавить тему без изменения кода (динамически)

- Текущая архитектура использует статический список ThemeStore.all и статические свойства Theme.* — динамическая загрузка тем (из JSON/плагинов) не реализована "из коробки".
- Для поддержки динамических тем можно:
  1. Расширить модель Theme, добавить инициализатор из словаря/JSON.
  2. Изменить ThemeStore.all на вычисляемое свойство или загрузчик, который читает встроенные + внешний каталог themes/ или UserDefaults/плагин.
  3. Реализовать сохранение/регистрацию новых тем в локальное хранилище и обновлять ThemeStore.current при регистрации.

Программа-пример: программно переключить тему

- Рекомендуется использовать ThemeStore:
    themeStore.select(key: "solarized")

- Или напрямую (менее предпочтительно):
    UserDefaults.standard.set("solarized", forKey: "selectedTheme")
    // затем принудительная перерисовка/обновление предусмотренных мест

Важные замечания и нюансы

- Fallback: Theme.forKey(_:) по умолчанию возвращает .dark для неизвестных ключей.
- ThemeStore.all — единый список доступных тем, используемый UI. Чтобы тема появлялась в Picker, нужно добавить её туда.
- AppTheme читает палитру напрямую из UserDefaults — это удобно, но стоит учитывать, что если вы захотите иметь инстанцируемую/тестируемую AppTheme (например, в unit-tests), придётся поменять реализацию на зависимость от ThemeStore.
- Локализация: не забудьте добавить ключ displayNameKey в соответствующие Localizable.strings.
- CardModifier и .cardStyle() автоматически используют AppTheme.surface и AppTheme.border, поэтому новые темы сразу применят оформление карточек.

Тестирование и отладка

- Для быстрой проверки можно временно вызвать themeStore.select(key:) в инициализации приложения.
- Проверьте значения Color(hex:) — некорректный hex по умолчанию создаёт чёрный цвет.
- Проверьте батарейный градиент (AppTheme.batteryGradient) — он использует AppTheme.green/yellow/red и accent.

Заключение

В этом проекте темы реализованы как встроенные статические Theme-объекты с палитрой цветов, управляемые ThemeStore и сохраняемые в UserDefaults (ключ "selectedTheme"). Для добавления новой темы нужно: определить Theme в Theme.swift, добавить его в ThemeStore.all, добавить локализованное имя в Resources/Localizable.strings и пересобрать приложение. Для более гибкого/динамического подхода потребуется расширение Theme и ThemeStore для загрузки тем из внешних источников (JSON/папки/плагинов).
