# Charger Monitor

macOS SwiftUI app for charger/session monitoring, battery health trends, and recommendations.

## Local build and test

```bash
if [ -f project.yml ]; then xcodegen generate; fi
xcodebuild -project ChargerMonitor.xcodeproj -scheme ChargerMonitor -configuration Debug build
xcodebuild test -project ChargerMonitor.xcodeproj -scheme ChargerMonitor -configuration Debug
```

## Local repository checks

```bash
./scripts/check_localization.swift
./scripts/check_hardcoded_strings.sh
```

## Theme export/migration

```bash
./scripts/theme_export.swift
```

## Documentation

- CI details: `docs/ci.md`
- Localization workflow: `docs/localization.md`
- Theme migration/export: `docs/theme_migration.md`
