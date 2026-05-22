import Foundation
import SwiftUI
import HazakuraLLMManagerCore

struct ConfigurationView: View {
    @ObservedObject var controller: ServerController
    @State private var selectedPresetIntent: LlamaServerPresetIntent = .standard
    @State private var isAdvancedExpanded = false
    private let portAvailabilityChecker = PortAvailabilityChecker()

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
                        detectedPaths: controller.detectedRuntimeExecutablePaths,
                        isHighlighted: controller.configuration.runtimeExecutablePath.isEmpty,
                        validationMessageKey: runtimePathValidationMessageKey,
                        stepLabel: "Step 1",
                        selectPath: controller.selectRuntimeExecutablePath
                    )

                    pathRow(
                        title: "Model",
                        helpTooltip: HelpTooltip.model(),
                        text: binding(\.modelPath),
                        buttonTitle: "Choose GGUF",
                        allowedExtensions: ["gguf"],
                        detectedPaths: [],
                        isHighlighted: controller.configuration.modelPath.isEmpty,
                        validationMessageKey: modelPathValidationMessageKey,
                        stepLabel: "Step 2",
                        selectPath: controller.selectModelPath
                    )

                    RuntimeDiagnosticsSectionView(controller: controller)

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

                            Text(LocalizedStringKey(presetDescriptionKey(for: selectedPresetIntent)))
                                .font(.caption)
                                .foregroundStyle(Color.accentColor)
                                .lineLimit(2)
                                .padding(.top, 2)

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

                VStack(alignment: .leading, spacing: 0) {
                    DisclosureSectionHeader(title: "Advanced Settings", isExpanded: $isAdvancedExpanded)

                    if isAdvancedExpanded {
                        Grid(alignment: .leading, horizontalSpacing: 12, verticalSpacing: 12) {
                            GridRow {
                                HStack(spacing: 4) {
                                    Text("Port")
                                        .foregroundStyle(.secondary)
                                    HelpTooltip.port()
                                }
                                HStack(spacing: 8) {
                                    TextField("1234", value: binding(\.port), format: .number)
                                        .glassTextFieldStyle()
                                        .frame(width: 110)

                                    if let portValidationMessageKey {
                                        Label(LocalizedStringKey(portValidationMessageKey), systemImage: "exclamationmark.triangle")
                                            .font(.caption)
                                            .foregroundStyle(.orange)
                                    }
                                }
                            }

                            GridRow {
                                HStack(spacing: 4) {
                                    Text("Context")
                                        .foregroundStyle(.secondary)
                                    HelpTooltip.contextSize()
                                }

                                HStack(spacing: 12) {
                                    Slider(value: contextSizeBinding, in: 1_024...1_048_576, step: 1024)
                                        .tint(.orange)

                                    TextField("32768", value: binding(\.contextSize), format: .number)
                                        .glassTextFieldStyle()
                                        .frame(width: 96)
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
                                            .lineLimit(1)
                                            .padding(.horizontal, 10)
                                            .padding(.vertical, 6)
                                            .background(RoundedRectangle(cornerRadius: 8).fill(.black.opacity(0.2)))
                                            .frame(width: 64)
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
                                            .lineLimit(1)
                                            .padding(.horizontal, 10)
                                            .padding(.vertical, 6)
                                            .background(RoundedRectangle(cornerRadius: 8).fill(.black.opacity(0.2)))
                                            .frame(width: 64)
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
        detectedPaths: [String],
        isHighlighted: Bool,
        validationMessageKey: String? = nil,
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

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    TextField(title, text: text)
                        .glassTextFieldStyle()
                        .overlay(
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(
                                    pathRowBorderColor(
                                        isHighlighted: isHighlighted,
                                        validationMessageKey: validationMessageKey
                                    ),
                                    lineWidth: 1.5
                                )
                        )

                    Button {
                        if let path = FilePanel.chooseFile(allowedExtensions: allowedExtensions) {
                            selectPath(path)
                        }
                    } label: {
                        Label(buttonTitle, systemImage: "folder")
                    }
                    .buttonStyle(SecondaryButtonStyle())

                    if !detectedPaths.isEmpty {
                        Menu {
                            ForEach(detectedPaths, id: \.self) { path in
                                Button {
                                    selectPath(path)
                                } label: {
                                    Text(pathMenuLabel(path))
                                }
                            }
                        } label: {
                            Label("Installed", systemImage: "checkmark.seal")
                        }
                        .buttonStyle(SecondaryButtonStyle())
                    }
                }

                if let validationMessageKey {
                    Label(LocalizedStringKey(validationMessageKey), systemImage: "exclamationmark.triangle")
                        .font(.caption)
                        .foregroundStyle(.orange)
                }
            }
        }
    }

    private func pathRowBorderColor(isHighlighted: Bool, validationMessageKey: String?) -> Color {
        if validationMessageKey != nil {
            return .orange.opacity(0.7)
        }

        return isHighlighted ? Color.accentColor.opacity(0.6) : .clear
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

    private func pathMenuLabel(_ path: String) -> String {
        let name = URL(fileURLWithPath: path).lastPathComponent
        guard !name.isEmpty else {
            return path
        }

        return "\(name) - \(path)"
    }

    private var runtimePathValidationMessageKey: String? {
        let path = controller.configuration.runtimeExecutablePath.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !path.isEmpty else {
            return nil
        }

        var isDirectory = ObjCBool(false)
        guard FileManager.default.fileExists(atPath: path, isDirectory: &isDirectory) else {
            return "validation.runtime.missing"
        }

        guard !isDirectory.boolValue else {
            return "validation.runtime.directory"
        }

        guard FileManager.default.isExecutableFile(atPath: path) else {
            return "validation.runtime.not_executable"
        }

        return nil
    }

    private var modelPathValidationMessageKey: String? {
        let path = controller.configuration.modelPath.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !path.isEmpty else {
            return nil
        }

        var isDirectory = ObjCBool(false)
        guard FileManager.default.fileExists(atPath: path, isDirectory: &isDirectory) else {
            return "validation.model.missing"
        }

        guard !isDirectory.boolValue else {
            return "validation.model.directory"
        }

        guard URL(fileURLWithPath: path).pathExtension.lowercased() == "gguf" else {
            return "validation.model.unsupported"
        }

        return nil
    }

    private var portValidationMessageKey: String? {
        guard controller.canStart else {
            return nil
        }

        guard (1...65535).contains(controller.configuration.port) else {
            return "validation.port.invalid"
        }

        guard portAvailabilityChecker.isPortAvailable(controller.configuration.port) else {
            return "validation.port.unavailable"
        }

        return nil
    }

    private func presetDescriptionKey(for intent: LlamaServerPresetIntent) -> String {
        switch intent {
        case .standard:
            return "preset.description.standard"
        case .qwenRecommended:
            return "preset.description.qwen"
        case .gemmaRecommended:
            return "preset.description.gemma"
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
