import AppKit
import SwiftUI

struct EndpointView: View {
    @ObservedObject var controller: ServerController

    var body: some View {
        GroupBox("Endpoint") {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text(controller.configuration.apiBaseURL)
                        .font(.system(.body, design: .monospaced))
                        .textSelection(.enabled)

                    Spacer()

                    Button {
                        copy(controller.configuration.apiBaseURL)
                    } label: {
                        Label("Copy Endpoint", systemImage: "doc.on.doc")
                    }
                }

                HStack(alignment: .top, spacing: 12) {
                    Text(controller.configuration.environmentSnippet)
                        .font(.system(.caption, design: .monospaced))
                        .foregroundStyle(.secondary)
                        .textSelection(.enabled)

                    Spacer()

                    Button {
                        copy(controller.configuration.environmentSnippet)
                    } label: {
                        Label("Copy Env", systemImage: "terminal")
                    }
                }
            }
        }
    }

    private func copy(_ value: String) {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(value, forType: .string)
    }
}
