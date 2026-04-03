# Charger Monitor — macOS SwiftUI (skeleton)

This repository contains a plan and an initial skeleton for a macOS SwiftUI application "Charger Monitor" that mirrors the existing charger_dashboard.html functionality.

What I did for Step 1 (Preparation)
- Backed up current artifacts to ./backups/: context.md, charger_dashboard.html, charger_server.sh
- Created a Swift Package skeleton (Package.swift) with targets: App, Domain, Data, Presentation
- Added minimal placeholder source files under Sources/* matching the plan structure
- Added a minimal SwiftUI App entry and a placeholder DashboardView

How to open in Xcode
1. Open `Package.swift` in Xcode (File → Open...). Xcode will treat the package as a project.
2. Set the deployment target in the Xcode scheme / project settings to macOS 13.0+ (Plan recommends macOS 13+).
3. To produce a universal build (Intel + Apple Silicon), ensure the Xcode build settings include both `arm64` and `x86_64` in Architectures (Any Mac)

Next steps (to implement after Step 1)
- Implement native IOKit-based SystemPowerRepository with proper parsing and permissions
- Create SessionStore implementations (SwiftData & File Codable fallback)
- Build Presentation views: PowerChartView (Swift Charts or custom Canvas), SessionsListView, SettingsView
- Add unit tests and CI build workflows

Files added
- Package.swift
- Sources/App/App.swift
- Sources/Domain/Models/BatterySample.swift
- Sources/Domain/Models/Session.swift
- Sources/Domain/UseCases/SessionUseCases.swift
- Sources/Data/SystemPower/SystemPowerRepository.swift
- Sources/Presentation/Views/DashboardView.swift
- Sources/Presentation/ViewModels/RealtimeViewModel.swift

Backups
- backups/charger_dashboard.html
- backups/charger_server.sh
- backups/context.md

If you want, I can:
- Generate a .xcodeproj (if your environment supports legacy generator) or provide an Xcode project.pbxproj template
- Implement the IOKit data fetcher or the File-based SessionStore next

Build / Release
----------------
This repository is structured as a Swift Package (Package.swift). You can open Package.swift directly in Xcode (File → Open...) and use Xcode to run, archive and produce a macOS .app or installer.

Recommended local steps to produce a universal (Intel + Apple Silicon) build:
1. Open `Package.swift` in Xcode.
2. In the project navigator select the package product or generated app target, then set the Deployment Target to macOS 13.0+ (or your desired minimum).
3. In the target Build Settings, ensure "Architectures" (ARCHS) includes both `arm64` and `x86_64` (set to "Any Mac").
4. Use Product → Archive to create an archive and export a signed/unsigned .app or .pkg.

Quick CI build (provided)
-------------------------
A simple GitHub Actions workflow is included to build and test the Swift package on macOS runners and upload the release artifact (compressed build folder). This produces a release tarball of the SwiftPM build output (useful for headless CI builds). See `.github/workflows/build.yml`.

Notes
-----
- For a proper App Store / distribution build you should create an Xcode project with a proper bundle identifier, signing and entitlements, or use Xcode's package-to-app flow and configure the Export options when archiving.
- If you prefer an explicit `.xcodeproj` in the repo, I can generate a minimal project template and wire it to the package sources.
