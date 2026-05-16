import SwiftUI

struct CommandPreviewView: View {
    @ObservedObject var controller: ServerController

    var body: some View {
        GroupBox("Launch Command") {
            Text(controller.launchCommandPreview)
                .font(.system(.caption, design: .monospaced))
                .foregroundStyle(.secondary)
                .textSelection(.enabled)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}
