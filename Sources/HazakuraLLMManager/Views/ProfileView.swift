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

                    Button {
                        importRuntimeProfile()
                    } label: {
                        Label("Import", systemImage: "square.and.arrow.down")
                    }
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
