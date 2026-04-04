import SwiftUI

public struct SettingsView: View {
    @EnvironmentObject var vm: SettingsViewModel
    @Environment(\.dismiss) var dismiss

    public init() {}

    public var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Settings")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(AppTheme.text)

            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("Poll interval")
                        .font(AppTheme.mono(size: 13))
                        .foregroundColor(AppTheme.text)
                    Spacer()
                    Stepper("\(vm.pollIntervalSeconds)s", value: $vm.pollIntervalSeconds, in: 1...60)
                        .font(AppTheme.mono(size: 13))
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(AppTheme.surface2)
                )
            }

            Spacer()

            HStack {
                Spacer()
                Button("Done") { dismiss() }
                    .font(.system(size: 13, weight: .semibold))
                    .padding(.horizontal, 20)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(AppTheme.accent)
                    )
                    .foregroundColor(.black)
                    .buttonStyle(.plain)
            }
        }
        .padding(24)
        .frame(minWidth: 360, minHeight: 200)
        .background(AppTheme.surface)
    }
}
