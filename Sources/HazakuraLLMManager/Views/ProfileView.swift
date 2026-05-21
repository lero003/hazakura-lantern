import SwiftUI

struct ProfileView: View {
    @ObservedObject var controller: ServerController

    var body: some View {
        GroupBox("Runtime Profile") {
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 10) {
                    Label(controller.activeProfileName, systemImage: "doc.text")
                        .lineLimit(1)
                        .truncationMode(.middle)

                    Spacer()

                    Button {
                        exportRuntimeProfile()
                    } label: {
                        Label("Export", systemImage: "square.and.arrow.up")
                    }
                    .accessibilityLabel(Text("Export Profile"))
                    .accessibilityHint(Text("Export the active runtime profile as a .lantern-profile.json file."))

                    Button {
                        importRuntimeProfile()
                    } label: {
                        Label("Import", systemImage: "square.and.arrow.down")
                    }
                    .accessibilityLabel(Text("Import Profile"))
                    .accessibilityHint(Text("Import a .lantern-profile.json file into the active configuration."))
                }

                if let message = controller.profileFileMessage {
                    Text(message)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
            }
            .padding(.vertical, 4)
        }
    }

    private func exportRuntimeProfile() {
        if let url = FilePanel.chooseProfileExportFile(
            suggestedFileName: controller.runtimeProfileDocument.suggestedExportFileName
        ) {
            controller.exportRuntimeProfile(to: url)
        }
    }

    private func importRuntimeProfile() {
        if let url = FilePanel.chooseProfileImportFile() {
            controller.importRuntimeProfile(from: url)
        }
    }
}
