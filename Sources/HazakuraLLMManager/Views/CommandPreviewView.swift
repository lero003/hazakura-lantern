import SwiftUI

struct CommandPreviewView: View {
    @ObservedObject var controller: ServerController
    @State private var didCopy = false
    @State private var copyGeneration = 0

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

                VStack(alignment: .trailing, spacing: 3) {
                    Button {
                        copyCommand()
                    } label: {
                        Label("Copy Command", systemImage: "doc.on.doc")
                    }
                    .buttonStyle(SecondaryButtonStyle())

                    Text("Copied!")
                        .font(.caption2)
                        .foregroundStyle(.green)
                        .opacity(didCopy ? 1 : 0)
                        .accessibilityHidden(!didCopy)
                        .frame(height: 12, alignment: .trailing)
                }
            }
            .padding(.vertical, 2)
        }
    }

    private func copyCommand() {
        PasteboardWriter.copy(controller.launchCommandPreview)
        copyGeneration += 1
        let generation = copyGeneration

        withAnimation(.easeInOut(duration: 0.15)) {
            didCopy = true
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.6) {
            guard copyGeneration == generation else {
                return
            }

            withAnimation(.easeInOut(duration: 0.2)) {
                didCopy = false
            }
        }
    }
}
