import SwiftUI
import Domain
import AppKit

extension Presentation {
    public struct SessionsListView: View {
        @EnvironmentObject var viewModel: SessionsViewModel
        @Environment(\.presentationMode) var presentation

        public init() {}

        public var body: some View {
            NavigationView {
                List {
                    ForEach(viewModel.sessions) { s in
                        VStack(alignment: .leading) {
                            HStack {
                                Text(s.startTimestamp, style: .date)
                                Text(s.startTimestamp, style: .time)
                                Spacer()
                                if let avg = s.avgW { Text(String(format: "Avg: %.1f W", avg)) }
                            }
                            HStack {
                                Text("Duration: \(Int(s.duration))s")
                                Spacer()
                                Text("Rating: \(s.rating)")
                            }
                        }
                        .contextMenu {
                            Button("Export JSON") {
                                if let txt = viewModel.exportJSON(session: s) {
                                    // copy to pasteboard for simplicity
                                    NSPasteboard.general.clearContents()
                                    NSPasteboard.general.setString(txt, forType: .string)
                                }
                            }
                            Button("Delete") {
                                Task { await viewModel.delete(s.id) }
                            }
                        }
                    }
                }
                .navigationTitle("Sessions")
                .toolbar {
                    ToolbarItem(placement: .primaryAction) {
                        Button("Close") { presentation.wrappedValue.dismiss() }
                    }
                }
            }
            .task { await viewModel.reload() }
        }
    }
}
