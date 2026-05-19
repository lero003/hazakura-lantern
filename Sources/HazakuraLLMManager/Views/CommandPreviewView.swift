import AppKit
import SwiftUI

struct CommandPreviewView: View {
    @ObservedObject var controller: ServerController

    var body: some View {
        GroupBox("Launch Command") {
            HStack(spacing: 8) {
                Text(controller.launchCommandPreview)
                    .font(.system(.caption, design: .monospaced))
                    .foregroundStyle(.primary.opacity(0.85))
                    .textSelection(.enabled)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(.black.opacity(0.22), in: RoundedRectangle(cornerRadius: 6))
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(Color.white.opacity(0.06), lineWidth: 1)
                    )

                Button {
                    copy(controller.launchCommandPreview)
                } label: {
                    Label("Copy Command", systemImage: "doc.on.doc")
                }
                .buttonStyle(SecondaryButtonStyle())
            }
            .padding(.vertical, 2)
        }
    }

    private func copy(_ value: String) {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(value, forType: .string)
    }
}
