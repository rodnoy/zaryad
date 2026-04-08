# Localization workflow

Localization files:

- `Resources/en.lproj/Localizable.strings` (source of truth)
- `Resources/ru.lproj/Localizable.strings`
- `Resources/fr.lproj/Localizable.strings`

## Add a new key

1. Add key/value in `en.lproj/Localizable.strings`.
2. Add the same key in `ru.lproj` and `fr.lproj`.
3. Use the key in SwiftUI (for example `Text("your.key")`).

## Validate parity

Run:

```bash
./scripts/check_localization.swift
```

The script fails when:

- a key exists in `en` but is missing in `ru` or `fr`,
- `ru` or `fr` contains extra keys not present in `en`.

## Recommended local check set

```bash
./scripts/check_localization.swift
./scripts/check_hardcoded_strings.sh
```
