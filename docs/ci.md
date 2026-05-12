# CI pipeline

GitHub Actions workflow: `.github/workflows/ci.yml`.

## What CI runs

On every `push` and `pull_request`:

1. Checkout repository.
2. Restore/cache Xcode DerivedData.
3. If `project.yml` exists:
   - install `xcodegen` (Homebrew) when missing,
   - run `xcodegen generate`.
4. Build app:

```bash
xcodebuild -project Zaryad.xcodeproj -scheme Zaryad -configuration Debug build
```

5. Run tests:

```bash
xcodebuild test -project Zaryad.xcodeproj -scheme Zaryad -configuration Debug
```

6. Run repository checks:

```bash
./scripts/check_localization.swift
./scripts/check_hardcoded_strings.sh
```

Any non-zero exit code fails CI.

## Run the same checks locally

```bash
if [ -f project.yml ]; then xcodegen generate; fi
xcodebuild -project Zaryad.xcodeproj -scheme Zaryad -configuration Debug build
xcodebuild test -project Zaryad.xcodeproj -scheme Zaryad -configuration Debug
./scripts/check_localization.swift
./scripts/check_hardcoded_strings.sh
```
