import Data
import Domain
import SwiftUI
import UniformTypeIdentifiers

public struct SettingsView: View {
    @EnvironmentObject var vm: SettingsViewModel
    @EnvironmentObject var themeStore: ThemeStore
    @Environment(\.dismiss) var dismiss

    @State private var importStatusMessage: String?
    @State private var importStatusIsError: Bool = false

    public init() {}

    public var body: some View {
        let p = themeStore.current.palette

        VStack(alignment: .leading, spacing: 16) {
            Text("settings.title")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(p.text)

            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("settings.theme")
                        .font(.system(size: 13, weight: .regular, design: .monospaced))
                        .foregroundColor(p.text)
                    Spacer()
                    Picker("settings.theme", selection: Binding(
                        get: { themeStore.currentKey },
                        set: { themeStore.select(key: $0) }
                    )) {
                        ForEach(ThemeStore.all, id: \.key) { theme in
                            Text(theme.displayNameKey) // localization-ok — displayNameKey is LocalizedStringKey
                                .foregroundColor(p.text)
                                .tag(theme.key)
                        }
                    }
                    .labelsHidden()
                    .pickerStyle(.menu)
                    .foregroundColor(p.text)
                    .font(.system(size: 13, weight: .regular, design: .monospaced))
                    .accessibilityLabel("settings.theme")
                    .help(Text("settings.theme"))
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(p.surface2)
                )

                HStack {
                    Text("settings.poll_interval")
                        .font(.system(size: 13, weight: .regular, design: .monospaced))
                        .foregroundColor(p.text)
                    Spacer()
                    Stepper("\(vm.pollIntervalSeconds)s", value: $vm.pollIntervalSeconds, in: 1...60)
                        .font(.system(size: 13, weight: .regular, design: .monospaced))
                        .accessibilityLabel("settings.poll_interval")
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(p.surface2)
                )

                HStack {
                    Button("settings.theme.reload") {
                        themeStore.reload()
                    }
                    .font(.system(size: 13, weight: .semibold, design: .monospaced))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(p.accent2.opacity(0.2))
                    )
                    .foregroundColor(p.text)
                    .buttonStyle(.plain)
                    .accessibilityLabel("settings.theme.reload")

                    Button("settings.theme.import") {
                        importThemeFromFile()
                    }
                    .font(.system(size: 13, weight: .semibold, design: .monospaced))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(p.accent2.opacity(0.2))
                    )
                    .foregroundColor(p.text)
                    .buttonStyle(.plain)
                    .accessibilityLabel("settings.theme.import")

                    Spacer()
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(p.surface2)
                )

                if let message = importStatusMessage {
                    HStack(spacing: 6) {
                        Image(systemName: importStatusIsError ? "xmark.circle.fill" : "checkmark.circle.fill")
                            .foregroundColor(importStatusIsError ? p.red : p.green)
                        Text(message)
                            .font(.system(size: 12, weight: .medium, design: .monospaced))
                            .foregroundColor(importStatusIsError ? p.red : p.green)
                        Spacer()
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .transition(.opacity)
                }
            }

            Spacer()

            HStack {
                Spacer()
                Button("btn.save") { dismiss() }
                    .font(.system(size: 13, weight: .semibold))
                    .padding(.horizontal, 20)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(p.accent)
                    )
                    .foregroundColor(p.text)
                    .buttonStyle(.plain)
                    .accessibilityLabel("btn.save")
            }
        }
        .padding(24)
        .frame(minWidth: 360, minHeight: 200)
        .background(p.surface)
    }

    // MARK: - Theme Import

    private func importThemeFromFile() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [UTType.json]
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        panel.title = String(localized: "settings.theme.import")

        guard panel.runModal() == .OK, let url = panel.url else { return }

        do {
            try themeStore.importTheme(from: url)
            withAnimation {
                importStatusMessage = String(localized: "settings.theme.import.success")
                importStatusIsError = false
            }
        } catch {
            withAnimation {
                importStatusMessage = error.localizedDescription
                importStatusIsError = true
            }
        }

        // Auto-dismiss status after 4 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 4) {
            withAnimation {
                importStatusMessage = nil
            }
        }
    }
}
