import Foundation
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
                    allowedExtensions: nil,
                    recentPaths: controller.recentPaths.runtimeExecutablePaths,
                    selectPath: controller.selectRuntimeExecutablePath
                )

                pathRow(
                    title: "Model",
                    text: binding(\.modelPath),
                    buttonTitle: "Choose GGUF",
                    allowedExtensions: ["gguf"],
                    recentPaths: controller.recentPaths.modelPaths,
                    selectPath: controller.selectModelPath
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
        allowedExtensions: [String]?,
        recentPaths: [String],
        selectPath: @escaping (String) -> Void
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
                        selectPath(path)
                    }
                } label: {
                    Label(buttonTitle, systemImage: "folder")
                }

                if !recentPaths.isEmpty {
                    Menu {
                        ForEach(recentPaths, id: \.self) { path in
                            Button {
                                selectPath(path)
                            } label: {
                                Text(recentPathLabel(path))
                            }
                        }
                    } label: {
                        Label("Recent", systemImage: "clock")
                    }
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

    private func recentPathLabel(_ path: String) -> String {
        let name = URL(fileURLWithPath: path).lastPathComponent
        guard !name.isEmpty else {
            return path
        }

        return "\(name) - \(path)"
    }
}
