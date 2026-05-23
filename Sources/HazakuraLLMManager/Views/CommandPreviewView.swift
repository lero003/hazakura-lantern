import SwiftUI

struct CommandPreviewView: View {
    @ObservedObject var controller: ServerController
    @State private var didCopy = false
    @State private var copyGeneration = 0

    var body: some View {
        GroupBox("Launch Command") {
            HStack(spacing: DesignTokens.Spacing.md) {
                Text(controller.launchCommandPreview)
                    .codeBlockStyle()
                    .foregroundStyle(.primary.opacity(DesignTokens.Opacity.textBody))
                    .frame(maxWidth: .infinity, alignment: .leading)

                VStack(alignment: .trailing, spacing: DesignTokens.Spacing.xxs) {
                    Button {
                        copyCommand()
                    } label: {
                        Label("Copy Command", systemImage: "doc.on.doc")
                    }
                    .buttonStyle(SecondaryButtonStyle())

                    Text("Copied!")
                        .font(DesignTokens.Font.captionSmall)
                        .foregroundStyle(.green)
                        .opacity(didCopy ? 1 : 0)
                        .accessibilityHidden(!didCopy)
                        .frame(height: 12, alignment: .trailing)
                }
            }
            .padding(.vertical, DesignTokens.Spacing.xxs)
        }
    }

    private func copyCommand() {
        PasteboardWriter.copy(controller.launchCommandPreview)
        copyGeneration += 1
        let generation = copyGeneration

        withAnimation(.easeInOut(duration: DesignTokens.Animation.snappy)) {
            didCopy = true
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + DesignTokens.Animation.copyFeedback) {
            guard copyGeneration == generation else { return }

            withAnimation(.easeInOut(duration: DesignTokens.Animation.defaultDur)) {
                didCopy = false
            }
        }
    }
}
