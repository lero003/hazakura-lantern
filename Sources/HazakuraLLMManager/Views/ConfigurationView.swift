import Foundation
import SwiftUI
import HazakuraLLMManagerCore

struct ConfigurationView: View {
    @ObservedObject var controller: ServerController
    @State private var selectedPresetIntent: LlamaServerPresetIntent = .balancedLocal
    @State private var isAdvancedExpanded = false

    private var selectedPreset: LlamaServerPreset {
        LlamaServerPreset.preset(for: selectedPresetIntent)
    }

    private var contextSizeBinding: Binding<Double> {
        Binding(
            get: { Double(controller.configuration.contextSize) },
            set: { val in
                controller.updateConfiguration { config in
                    config.contextSize = Int(val)
                }
            }
        )
    }

    private var threadsAutoBinding: Binding<Bool> {
        Binding(
            get: { controller.configuration.threads == "auto" },
            set: { isAuto in
                controller.updateConfiguration { config in
                    config.threads = isAuto ? "auto" : "4"
                }
            }
        )
    }

    private var threadsValueBinding: Binding<Double> {
        Binding(
            get: { Double(Int(controller.configuration.threads) ?? 4) },
            set: { val in
                controller.updateConfiguration { config in
                    config.threads = String(Int(val))
                }
            }
        )
    }

    private var gpuLayersAutoBinding: Binding<Bool> {
        Binding(
            get: { controller.configuration.gpuLayers == "auto" },
            set: { isAuto in
                controller.updateConfiguration { config in
                    config.gpuLayers = isAuto ? "auto" : "0"
                }
            }
        )
    }

    private var gpuLayersValueBinding: Binding<Double> {
        Binding(
            get: { Double(Int(controller.configuration.gpuLayers) ?? 0) },
            set: { val in
                controller.updateConfiguration { config in
                    config.gpuLayers = String(Int(val))
                }
            }
        )
    }

    var body: some View {
        GroupBox("Server Configuration") {
            VStack(alignment: .leading, spacing: 16) {
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

                            if let advice = controller.runtimeInstallSourceAdvice {
                                VStack(alignment: .leading, spacing: 2) {
                                    Label(advice.title, systemImage: "arrow.triangle.2.circlepath.circle")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)

                                    Text(advice.detail)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                        .lineLimit(2)
                                }
                            }

                            if let advice = controller.runtimeUpdateReadinessAdvice {
                                VStack(alignment: .leading, spacing: 2) {
                                    Label(advice.title, systemImage: "checklist")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)

                                    Text(advice.detail)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                        .lineLimit(3)
                                }
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
                }

                Divider()
                    .padding(.vertical, 4)

                DisclosureGroup("Advanced Settings", isExpanded: $isAdvancedExpanded) {
                    Grid(alignment: .leading, horizontalSpacing: 12, verticalSpacing: 12) {
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

                            HStack(spacing: 12) {
                                Slider(value: contextSizeBinding, in: 1024...32768, step: 1024)
                                    .tint(.orange)

                                TextField("32768", value: binding(\.contextSize), format: .number)
                                    .glassTextFieldStyle()
                                    .frame(width: 80)
                            }
                        }

                        GridRow {
                            HStack(spacing: 4) {
                                Text("Threads")
                                    .foregroundStyle(.secondary)
                                HelpTooltip.threads()
                            }

                            HStack(spacing: 12) {
                                Toggle("auto", isOn: threadsAutoBinding)
                                    .toggleStyle(.checkbox)

                                if controller.configuration.threads != "auto" {
                                    Slider(value: threadsValueBinding, in: 1...32, step: 1)
                                        .tint(.orange)

                                    TextField("4", text: binding(\.threads))
                                        .glassTextFieldStyle()
                                        .frame(width: 50)
                                } else {
                                    Text("auto")
                                        .foregroundStyle(.secondary)
                                        .font(.system(.body, design: .monospaced))
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 6)
                                        .background(RoundedRectangle(cornerRadius: 8).fill(.black.opacity(0.2)))
                                        .frame(width: 50)
                                }
                            }
                        }

                        GridRow {
                            HStack(spacing: 4) {
                                Text("GPU Layers")
                                    .foregroundStyle(.secondary)
                                HelpTooltip.gpuLayers()
                            }

                            HStack(spacing: 12) {
                                Toggle("auto", isOn: gpuLayersAutoBinding)
                                    .toggleStyle(.checkbox)

                                if controller.configuration.gpuLayers != "auto" {
                                    Slider(value: gpuLayersValueBinding, in: 0...128, step: 1)
                                        .tint(.orange)

                                    TextField("0", text: binding(\.gpuLayers))
                                        .glassTextFieldStyle()
                                        .frame(width: 50)
                                } else {
                                    Text("auto")
                                        .foregroundStyle(.secondary)
                                        .font(.system(.body, design: .monospaced))
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 6)
                                        .background(RoundedRectangle(cornerRadius: 8).fill(.black.opacity(0.2)))
                                        .frame(width: 50)
                                }
                            }
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
                    .padding(.top, 10)
                }
                .accentColor(.orange)
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
