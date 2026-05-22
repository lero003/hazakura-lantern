import SwiftUI
import HazakuraLLMManagerCore

struct SettingsView: View {
    var maxContentWidth: CGFloat = 560

    @AppStorage(AppLanguage.storageKey) private var languageRawValue = AppLanguage.system.rawValue

    private var languageSelection: Binding<AppLanguage> {
        Binding(
            get: { AppLanguage(rawValue: languageRawValue) ?? .system },
            set: { languageRawValue = $0.rawValue }
        )
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            GroupBox("Language") {
                VStack(alignment: .leading, spacing: 10) {
                    Picker("Language", selection: languageSelection) {
                        ForEach(AppLanguage.allCases) { language in
                            Text(language.titleKey)
                                .tag(language)
                        }
                    }
                    .labelsHidden()
                    .pickerStyle(.segmented)
                    .frame(maxWidth: 360, alignment: .leading)

                    Text("Language changes apply to UI labels and controls only.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            GroupBox("Source Checkpoint") {
                VStack(alignment: .leading, spacing: 8) {
                    HStack(alignment: .firstTextBaseline, spacing: 12) {
                        Text("Source checkpoint")
                            .foregroundStyle(.secondary)
                            .frame(width: 150, alignment: .leading)

                        Text(SourceCheckpointInfo.current.identifier)
                            .font(.body.weight(.semibold))
                            .textSelection(.enabled)
                    }

                    Text("Source-only release candidate; no packaged app artifact is included.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .frame(minWidth: 360, maxWidth: maxContentWidth, alignment: .topLeading)
    }
}
