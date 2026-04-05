import Presentation
import Domain
import Data
import SwiftUI

struct ThemeCommands: Commands {
    @EnvironmentObject private var themeStore: ThemeStore

    var body: some Commands {
        CommandMenu("Theme") {
            Picker("settings.theme", selection: Binding(
                get: { themeStore.currentKey },
                set: { themeStore.select(key: $0) }
            )) {
                ForEach(ThemeStore.all, id: \.key) { theme in
                    Text(theme.displayNameKey)
                        .tag(theme.key)
                }
            }
        }
    }
}
