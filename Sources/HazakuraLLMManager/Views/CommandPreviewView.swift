import AppKit
import SwiftUI

struct CommandPreviewView: View {
    @ObservedObject var controller: ServerController

    var body: some View {
        GroupBox("Launch Command") {
            HStack(alignment: .top, spacing: 12) {
                Text(controller.launchCommandPreview)
                    .font(.system(.caption, design: .monospaced))
                    .foregroundStyle(.secondary)
                    .textSelection(.enabled)
                    .frame(maxWidth: .infinity, alignment: .leading)

                Button {
                    copy(controller.launchCommandPreview)
                } label: {
                    Label("Copy Command", systemImage: "doc.on.doc")
                }
            }
        }
    }

    private func copy(_ value: String) {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(value, forType: .string)
    }
}
