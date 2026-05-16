import SwiftUI
import HazakuraLLMManagerCore

struct ConfigurationView: View {
    @ObservedObject var controller: ServerController

    var body: some View {
        GroupBox("Server Configuration") {
            Grid(alignment: .leading, horizontalSpacing: 12, verticalSpacing: 12) {
                pathRow(
                    title: "Runtime",
                    text: binding(\.runtimeExecutablePath),
                    buttonTitle: "Choose Runtime",
                    allowedExtensions: nil
                )

                pathRow(
                    title: "Model",
                    text: binding(\.modelPath),
                    buttonTitle: "Choose GGUF",
                    allowedExtensions: ["gguf"]
                )

                GridRow {
                    Text("Port")
                        .foregroundStyle(.secondary)
                    TextField("1234", value: binding(\.port), format: .number)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 110)
                }

                GridRow {
                    Text("Context")
                        .foregroundStyle(.secondary)
                    TextField("32768", value: binding(\.contextSize), format: .number)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 110)
                }

                GridRow {
                    Text("Threads")
                        .foregroundStyle(.secondary)
                    TextField("auto", text: binding(\.threads))
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 110)
                }

                GridRow {
                    Text("GPU Layers")
                        .foregroundStyle(.secondary)
                    TextField("auto", text: binding(\.gpuLayers))
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 110)
                }

                GridRow {
                    Text("Additional Args")
                        .foregroundStyle(.secondary)
                    TextField("--verbose", text: binding(\.additionalArguments))
                        .textFieldStyle(.roundedBorder)
                        .font(.system(.body, design: .monospaced))
                }
            }
            .padding(.vertical, 4)

            Divider()
                .padding(.vertical, 8)

            HStack(spacing: 10) {
                Button {
                    controller.start()
                } label: {
                    Label("Start", systemImage: "play.fill")
                }
                .keyboardShortcut(.defaultAction)
                .disabled(!controller.canStart)

                Button {
                    controller.stop()
                } label: {
                    Label("Stop", systemImage: "stop.fill")
                }
                .disabled(!controller.canStop)

                Button {
                    controller.restart()
                } label: {
                    Label("Restart", systemImage: "arrow.clockwise")
                }
                .disabled(!controller.canRestart)

                Spacer()

                if let message = controller.lastErrorMessage {
                    Label(message, systemImage: "exclamationmark.triangle")
                        .foregroundStyle(.red)
                        .font(.caption)
                        .lineLimit(2)
                }
            }
        }
    }

    private func pathRow(
        title: String,
        text: Binding<String>,
        buttonTitle: String,
        allowedExtensions: [String]?
    ) -> some View {
        GridRow {
            Text(title)
                .foregroundStyle(.secondary)

            HStack(spacing: 8) {
                TextField(title, text: text)
                    .textFieldStyle(.roundedBorder)
                    .font(.system(.body, design: .monospaced))

                Button {
                    if let path = FilePanel.chooseFile(allowedExtensions: allowedExtensions) {
                        text.wrappedValue = path
                    }
                } label: {
                    Label(buttonTitle, systemImage: "folder")
                }
            }
        }
    }

    private func binding<Value>(_ keyPath: WritableKeyPath<RuntimeConfiguration, Value>) -> Binding<Value> {
        Binding(
            get: { controller.configuration[keyPath: keyPath] },
            set: { value in
                controller.updateConfiguration { configuration in
                    configuration[keyPath: keyPath] = value
                }
            }
        )
    }
}
