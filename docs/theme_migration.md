# Theme migration/export

Script: `scripts/theme_export.swift`.

## Purpose

Exports built-in theme definitions into JSON files in `Resources/Themes` and creates a backup of:

- `Sources/Presentation/Theme/Theme.swift`

Backup filename format:

- `Theme.swift.backup.<ISO8601 timestamp>`

## Run

From repository root:

```bash
./scripts/theme_export.swift
```

or

```bash
swift scripts/theme_export.swift
```

## Outputs

- `Resources/Themes/dark.json`
- `Resources/Themes/light.json`
- `Resources/Themes/forest.json`
- `Resources/Themes/marine.json`
- `Resources/Themes/martian.json`

## User themes location

Runtime user themes are loaded from:

- `~/.chargermonitor/themes`

JSON files in that directory override built-in themes by key.
