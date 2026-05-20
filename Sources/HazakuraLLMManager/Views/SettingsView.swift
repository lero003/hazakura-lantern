import SwiftUI

struct SettingsView: View {
    @AppStorage(AppLanguage.storageKey) private var languageRawValue = AppLanguage.system.rawValue

    private var languageSelection: Binding<AppLanguage> {
        Binding(
            get: { AppLanguage(rawValue: languageRawValue) ?? .system },
            set: { languageRawValue = $0.rawValue }
        )
    }

    var body: some View {
        Form {
            Picker("Language", selection: languageSelection) {
                ForEach(AppLanguage.allCases) { language in
                    Text(language.titleKey)
                        .tag(language)
                }
            }
            .pickerStyle(.segmented)

            Text("Language changes apply to UI labels and controls only.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(20)
        .frame(width: 420)
    }
}
