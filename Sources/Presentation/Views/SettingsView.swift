import SwiftUI

extension Presentation {
    public struct SettingsView: View {
        @EnvironmentObject var vm: SettingsViewModel
        @Environment(\.presentationMode) var presentation

        public init() {}

        public var body: some View {
            VStack(alignment: .leading, spacing: 12) {
                Form {
                    Stepper("Poll interval: \(vm.pollIntervalSeconds)s", value: $vm.pollIntervalSeconds, in: 1...60)
                    Toggle("Use SwiftData (if available)", isOn: $vm.useSwiftData)
                    // Removed web exporter toggle — this project provides a native SwiftUI dashboard only.
                }

                HStack {
                    Spacer()
                    Button("Done") { presentation.wrappedValue.dismiss() }
                }
            }
            .padding()
            .frame(minWidth: 320, minHeight: 220)
        }
    }
}
