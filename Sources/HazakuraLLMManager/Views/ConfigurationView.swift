import Foundation
import SwiftUI
import HazakuraLLMManagerCore

struct ConfigurationView: View {
    @ObservedObject var controller: ServerController
    @State private var selectedPresetIntent: LlamaServerPresetIntent = .balancedLocal

    private var selectedPreset: LlamaServerPreset {
        LlamaServerPreset.preset(for: selectedPresetIntent)
    }

    var body: some View {
        GroupBox("Server Configuration") {
            Grid(alignment: .leading, horizontalSpacing: 12, verticalSpacing: 12) {
                pathRow(
                    title: "Runtime",
                    helpTooltip: HelpTooltip.runtime(),
                    text: binding(\.runtimeExecutablePath),
                    buttonTitle: "Choose Runtime",
                    allowedExtensions: nil,
                    recentPaths: controller.recentPaths.runtimeExecutablePaths,
                    isHighlighted: controller.configuration.runtimeExecutablePath.isEmpty,
                    stepLabel: "Step 1",
                    selectPath: controller.selectRuntimeExecutablePath
                )

                pathRow(
                    title: "Model",
                    helpTooltip: HelpTooltip.model(),
                    text: binding(\.modelPath),
                    buttonTitle: "Choose GGUF",
                    allowedExtensions: ["gguf"],
                    recentPaths: controller.recentPaths.modelPaths,
                    isHighlighted: controller.configuration.modelPath.isEmpty,
                    stepLabel: "Step 2",
                    selectPath: controller.selectModelPath
                )

                GridRow {
                    Text("Preset")
                        .foregroundStyle(.secondary)

                    VStack(alignment: .leading, spacing: 6) {
                        HStack(spacing: 8) {
                            Picker("Preset", selection: $selectedPresetIntent) {
                                ForEach(LlamaServerPreset.all, id: \.intent) { preset in
                                    Text(preset.displayName)
                                        .tag(preset.intent)
                                }
                            }
                            .labelsHidden()
                            .pickerStyle(.menu)
                            .frame(width: 180)

                            Button {
                                controller.applyPreset(selectedPreset)
                            } label: {
                                Label("Apply Preset", systemImage: "slider.horizontal.3")
                            }
                            .buttonStyle(SecondaryButtonStyle())
                        }

                        Text(selectedPreset.previewSummary)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(2)

                        Text(presetDescriptionJP(for: selectedPresetIntent))
                            .font(.caption)
                            .foregroundStyle(Color.accentColor)
                            .lineLimit(2)
                            .padding(.top, 2)

                        HStack(spacing: 8) {
                            Button {
                                controller.checkRuntimeCapabilities()
                            } label: {
                                Label("Check Runtime", systemImage: "checkmark.shield")
                            }
                            .buttonStyle(SecondaryButtonStyle())
                            .disabled(controller.isRuntimeCapabilityProbeRunning)

                            if controller.isRuntimeCapabilityProbeRunning {
                                ProgressView()
                                    .controlSize(.small)
                            }
                        }

                        if let message = controller.runtimeCapabilityProbeMessage {
                            Label(message, systemImage: "info.circle")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        if let note = controller.runtimeCapabilityProbeResult?.presetCompatibilityNote(for: selectedPreset) {
                            VStack(alignment: .leading, spacing: 2) {
                                Label(note.title, systemImage: compatibilitySystemImage(for: note.severity))
                                    .font(.caption)
                                    .foregroundStyle(compatibilityForegroundStyle(for: note.severity))

                                Text(note.detail)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .lineLimit(2)
                            }
                        }
                    }
                }

                GridRow {
                    HStack(spacing: 4) {
                        Text("Port")
                            .foregroundStyle(.secondary)
                        HelpTooltip.port()
                    }
                    TextField("1234", value: binding(\.port), format: .number)
                        .glassTextFieldStyle()
                        .frame(width: 110)
                }

                GridRow {
                    HStack(spacing: 4) {
                        Text("Context")
                            .foregroundStyle(.secondary)
                        HelpTooltip.contextSize()
                    }
                    TextField("32768", value: binding(\.contextSize), format: .number)
                        .glassTextFieldStyle()
                        .frame(width: 110)
                }

                GridRow {
                    HStack(spacing: 4) {
                        Text("Threads")
                            .foregroundStyle(.secondary)
                        HelpTooltip.threads()
                    }
                    TextField("auto", text: binding(\.threads))
                        .glassTextFieldStyle()
                        .frame(width: 110)
                }

                GridRow {
                    HStack(spacing: 4) {
                        Text("GPU Layers")
                            .foregroundStyle(.secondary)
                        HelpTooltip.gpuLayers()
                    }
                    TextField("auto", text: binding(\.gpuLayers))
                        .glassTextFieldStyle()
                        .frame(width: 110)
                }

                GridRow {
                    HStack(spacing: 4) {
                        Text("Additional Args")
                            .foregroundStyle(.secondary)
                        HelpTooltip.additionalArguments()
                    }
                    TextField("--verbose", text: binding(\.additionalArguments))
                        .glassTextFieldStyle()
                }
            }
            .padding(.vertical, 4)

            Divider()
                .padding(.vertical, 8)

            if let launchSetupHint = controller.launchSetupHint {
                Label(launchSetupHint, systemImage: "info.circle")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.bottom, 4)
            }

            HStack(spacing: 12) {
                Button {
                    controller.start()
                } label: {
                    Label("Start", systemImage: "play.fill")
                }
                .buttonStyle(PrimaryButtonStyle())
                .keyboardShortcut(.defaultAction)
                .disabled(!controller.canStart)

                Button {
                    controller.stop()
                } label: {
                    Label("Stop", systemImage: "stop.fill")
                }
                .buttonStyle(SecondaryButtonStyle())
                .disabled(!controller.canStop)

                Button {
                    controller.restart()
                } label: {
                    Label("Restart", systemImage: "arrow.clockwise")
                }
                .buttonStyle(SecondaryButtonStyle())
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
        helpTooltip: HelpTooltip,
        text: Binding<String>,
        buttonTitle: String,
        allowedExtensions: [String]?,
        recentPaths: [String],
        isHighlighted: Bool,
        stepLabel: String?,
        selectPath: @escaping (String) -> Void
    ) -> some View {
        GridRow {
            HStack(spacing: 4) {
                if let stepLabel, isHighlighted {
                    Text(stepLabel)
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.accentColor, in: Capsule())
                }
                Text(title)
                    .foregroundStyle(.secondary)
                helpTooltip
            }

            HStack(spacing: 8) {
                TextField(title, text: text)
                    .glassTextFieldStyle()
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(isHighlighted ? Color.accentColor.opacity(0.6) : Color.clear, lineWidth: 1.5)
                    )

                Button {
                    if let path = FilePanel.chooseFile(allowedExtensions: allowedExtensions) {
                        selectPath(path)
                    }
                } label: {
                    Label(buttonTitle, systemImage: "folder")
                }
                .buttonStyle(SecondaryButtonStyle())

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
                    .buttonStyle(SecondaryButtonStyle())
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

    private func presetDescriptionJP(for intent: LlamaServerPresetIntent) -> String {
        switch intent {
        case .conservative:
            return "【推奨：入門・控えめ設定】メモリ消費が最も少なく、古いMacやバックグラウンド動作に最適です。"
        case .balancedLocal:
            return "【推奨：迷ったらこれ！】速度とメモリ消費のバランスが良く、M1以降のMacで標準的に動作します。"
        case .longContext:
            return "【推奨：長文読解用】多くの会話履歴やドキュメントを処理できますが、メモリ消費が大幅に増加します。"
        case .lowMemory:
            return "【推奨：メモリ8GB等の環境】GPUを使用せずCPUのみで動作させ、メモリ不足による強制終了を防ぎます。"
        case .mtpCapable:
            return "【推奨：高速推論】ドラフトモデルを使用した並列推論向けの設定です。対応するランタイムが必要です。"
        }
    }

    private func compatibilitySystemImage(for severity: LlamaServerPresetCompatibilityNote.Severity) -> String {
        switch severity {
        case .supported:
            return "checkmark.circle"
        case .warning:
            return "exclamationmark.triangle"
        case .unknown:
            return "questionmark.circle"
        }
    }

    private func compatibilityForegroundStyle(for severity: LlamaServerPresetCompatibilityNote.Severity) -> Color {
        switch severity {
        case .supported:
            return .green
        case .warning:
            return .orange
        case .unknown:
            return .secondary
        }
    }
}
