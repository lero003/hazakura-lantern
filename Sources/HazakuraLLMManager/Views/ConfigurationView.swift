import Foundation
import SwiftUI
import HazakuraLLMManagerCore

struct ConfigurationView: View {
    @ObservedObject var controller: ServerController
    @State private var selectedPresetIntent: LlamaServerPresetIntent = .standard
    @State private var isAdvancedExpanded = true
    @State private var isRuntimeDiagnosticsExpanded = true

    private let labelColumnWidth: CGFloat = 142
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

    private var threadsModeBinding: Binding<String> {
        Binding(
            get: { controller.configuration.threads == "auto" ? "auto" : "manual" },
            set: { mode in
                controller.updateConfiguration { config in
                    if mode == "auto" {
                        config.threads = "auto"
                    } else if config.threads == "auto" {
                        config.threads = "4"
                    }
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

    private var gpuLayersModeBinding: Binding<String> {
        Binding(
            get: { controller.configuration.gpuLayers == "auto" ? "auto" : "manual" },
            set: { mode in
                controller.updateConfiguration { config in
                    if mode == "auto" {
                        config.gpuLayers = "auto"
                    } else if config.gpuLayers == "auto" {
                        config.gpuLayers = "0"
                    }
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
        VStack(alignment: .leading, spacing: 16) {
            configurationCard(title: "Runtime & Model") {
                VStack(alignment: .leading, spacing: 14) {
                    pathRow(
                        title: "Runtime",
                        helpTooltip: HelpTooltip.runtime(),
                        text: binding(\.runtimeExecutablePath),
                        buttonTitle: "Choose",
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
                        buttonTitle: "Choose",
                        allowedExtensions: ["gguf"],
                        detectedPaths: [],
                        isHighlighted: controller.configuration.modelPath.isEmpty,
                        validationMessageKey: modelPathValidationMessageKey,
                        stepLabel: "Step 2",
                        selectPath: controller.selectModelPath
                    )
                }
            }

            configurationCard(title: "Launch Preset") {
                presetSection
            }

            collapsibleConfigurationCard(title: "Advanced Parameters", isExpanded: $isAdvancedExpanded) {
                advancedSection
            }

            collapsibleConfigurationCard(title: "Runtime Diagnostics", isExpanded: $isRuntimeDiagnosticsExpanded) {
                RuntimeDiagnosticsSectionView(controller: controller)
            }
        }
    }

    @ViewBuilder
    private var presetSection: some View {
        formRow(title: "Preset") {
            VStack(alignment: .leading, spacing: 8) {
                ViewThatFits(in: .horizontal) {
                    HStack(spacing: 8) {
                        presetControls
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        presetControls
                    }
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

    @ViewBuilder
    private var presetControls: some View {
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

    @ViewBuilder
    private var advancedSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            formRow(title: "Port", helpTooltip: HelpTooltip.port()) {
                ViewThatFits(in: .horizontal) {
                    HStack(spacing: 8) {
                        portField
                        portValidationLabel
                    }

                    VStack(alignment: .leading, spacing: 6) {
                        portField
                        portValidationLabel
                    }
                }
            }

            formRow(title: "Context", helpTooltip: HelpTooltip.contextSize()) {
                HStack(spacing: 12) {
                    Slider(value: contextSizeBinding, in: 1_024...1_048_576, step: 1024)
                        .tint(Color.accentColor)

                    TextField("32768", value: binding(\.contextSize), format: .number)
                        .glassTextFieldStyle()
                        .frame(width: 96)
                }
            }

            formRow(title: "Threads", helpTooltip: HelpTooltip.threads()) {
                parameterRow(
                    modeSelection: threadsModeBinding,
                    isManual: controller.configuration.threads != "auto"
                ) {
                    Slider(value: threadsValueBinding, in: 1...32, step: 1)
                        .tint(Color.accentColor)

                    TextField("4", text: binding(\.threads))
                        .glassTextFieldStyle()
                        .frame(width: 54)
                }
            }

            formRow(title: "GPU Layers", helpTooltip: HelpTooltip.gpuLayers()) {
                parameterRow(
                    modeSelection: gpuLayersModeBinding,
                    isManual: controller.configuration.gpuLayers != "auto"
                ) {
                    Slider(value: gpuLayersValueBinding, in: 0...128, step: 1)
                        .tint(Color.accentColor)

                    TextField("0", text: binding(\.gpuLayers))
                        .glassTextFieldStyle()
                        .frame(width: 54)
                }
            }

            formRow(title: "Additional Args", helpTooltip: HelpTooltip.additionalArguments()) {
                TextField("--verbose", text: binding(\.additionalArguments), axis: .vertical)
                    .lineLimit(2...4)
                    .glassTextFieldStyle()
                    .frame(maxWidth: .infinity)
            }
        }
    }

    @ViewBuilder
    private var portField: some View {
        TextField("1234", value: binding(\.port), format: .number)
            .glassTextFieldStyle()
            .frame(width: 110)
    }

    @ViewBuilder
    private var portValidationLabel: some View {
        if let portValidationMessageKey {
            Label(LocalizedStringKey(portValidationMessageKey), systemImage: "exclamationmark.triangle")
                .font(.caption)
                .foregroundStyle(validationColor(for: portValidationMessageKey))
        }
    }

    private func configurationCard<Content: View>(
        title: LocalizedStringKey,
        @ViewBuilder content: () -> Content
    ) -> some View {
        GroupBox {
            VStack(alignment: .leading, spacing: 14) {
                Text(title)
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(.primary.opacity(0.92))

                content()
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private func collapsibleConfigurationCard<Content: View>(
        title: LocalizedStringKey,
        isExpanded: Binding<Bool>,
        @ViewBuilder content: @escaping () -> Content
    ) -> some View {
        GroupBox {
            VStack(alignment: .leading, spacing: 12) {
                DisclosureSectionHeader(title: title, isExpanded: isExpanded)

                if isExpanded.wrappedValue {
                    content()
                        .padding(.top, 4)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private func formRow<Content: View>(
        title: LocalizedStringKey,
        helpTooltip: HelpTooltip? = nil,
        @ViewBuilder content: () -> Content
    ) -> some View {
        HStack(alignment: .top, spacing: 16) {
            HStack(spacing: 5) {
                Text(title)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)

                if let helpTooltip {
                    helpTooltip
                }
            }
            .frame(width: labelColumnWidth, alignment: .leading)
            .padding(.top, 6)

            content()
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private func parameterRow<Controls: View>(
        modeSelection: Binding<String>,
        isManual: Bool,
        @ViewBuilder manualControls: () -> Controls
    ) -> some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: 12) {
                modePicker(selection: modeSelection)

                if isManual {
                    manualControls()
                } else {
                    autoValuePill
                }
            }

            VStack(alignment: .leading, spacing: 8) {
                modePicker(selection: modeSelection)

                if isManual {
                    HStack(spacing: 12) {
                        manualControls()
                    }
                } else {
                    autoValuePill
                }
            }
        }
    }

    private func modePicker(selection: Binding<String>) -> some View {
        Picker("Mode", selection: selection) {
            Text("Auto")
                .tag("auto")
            Text("Manual")
                .tag("manual")
        }
        .labelsHidden()
        .pickerStyle(.segmented)
        .frame(width: 138)
    }

    private var autoValuePill: some View {
        Text("auto")
            .foregroundStyle(.secondary)
            .font(.system(.body, design: .monospaced))
            .lineLimit(1)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(RoundedRectangle(cornerRadius: 8).fill(.black.opacity(0.14)))
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(.white.opacity(0.08), lineWidth: 1)
            )
            .frame(width: 64)
    }

    private func pathRow(
        title: LocalizedStringKey,
        helpTooltip: HelpTooltip,
        text: Binding<String>,
        buttonTitle: LocalizedStringKey,
        allowedExtensions: [String]?,
        detectedPaths: [String],
        isHighlighted: Bool,
        validationMessageKey: String? = nil,
        stepLabel: String?,
        selectPath: @escaping (String) -> Void
    ) -> some View {
        formRow(title: title, helpTooltip: helpTooltip) {
            VStack(alignment: .leading, spacing: 6) {
                if let stepLabel, isHighlighted {
                    Text(stepLabel)
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.accentColor, in: Capsule())
                }

                ViewThatFits(in: .horizontal) {
                    pathControlRow(
                        title: title,
                        text: text,
                        buttonTitle: buttonTitle,
                        allowedExtensions: allowedExtensions,
                        detectedPaths: detectedPaths,
                        isHighlighted: isHighlighted,
                        validationMessageKey: validationMessageKey,
                        selectPath: selectPath
                    )

                    VStack(alignment: .leading, spacing: 8) {
                        pathControlStack(
                            title: title,
                            text: text,
                            buttonTitle: buttonTitle,
                            allowedExtensions: allowedExtensions,
                            detectedPaths: detectedPaths,
                            isHighlighted: isHighlighted,
                            validationMessageKey: validationMessageKey,
                            selectPath: selectPath
                        )
                    }
                }

                if !text.wrappedValue.isEmpty {
                    Text(pathCaption(text.wrappedValue))
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .truncationMode(.middle)
                        .help(text.wrappedValue)
                }

                if let validationMessageKey {
                    Label(LocalizedStringKey(validationMessageKey), systemImage: "exclamationmark.triangle")
                        .font(.caption)
                        .foregroundStyle(validationColor(for: validationMessageKey))
                }
            }
        }
    }

    private func pathControlRow(
        title: LocalizedStringKey,
        text: Binding<String>,
        buttonTitle: LocalizedStringKey,
        allowedExtensions: [String]?,
        detectedPaths: [String],
        isHighlighted: Bool,
        validationMessageKey: String?,
        selectPath: @escaping (String) -> Void
    ) -> some View {
        HStack(spacing: 8) {
            pathField(
                title: title,
                text: text,
                isHighlighted: isHighlighted,
                validationMessageKey: validationMessageKey
            )

            pathActionControls(
                buttonTitle: buttonTitle,
                allowedExtensions: allowedExtensions,
                detectedPaths: detectedPaths,
                selectPath: selectPath
            )
        }
    }

    private func pathControlStack(
        title: LocalizedStringKey,
        text: Binding<String>,
        buttonTitle: LocalizedStringKey,
        allowedExtensions: [String]?,
        detectedPaths: [String],
        isHighlighted: Bool,
        validationMessageKey: String?,
        selectPath: @escaping (String) -> Void
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            pathField(
                title: title,
                text: text,
                isHighlighted: isHighlighted,
                validationMessageKey: validationMessageKey
            )

            HStack(spacing: 8) {
                pathActionControls(
                    buttonTitle: buttonTitle,
                    allowedExtensions: allowedExtensions,
                    detectedPaths: detectedPaths,
                    selectPath: selectPath
                )
            }
        }
    }

    private func pathField(
        title: LocalizedStringKey,
        text: Binding<String>,
        isHighlighted: Bool,
        validationMessageKey: String?
    ) -> some View {
        TextField(title, text: text)
            .glassTextFieldStyle()
            .frame(minWidth: 240)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(
                        pathRowBorderColor(
                            isHighlighted: isHighlighted,
                            validationMessageKey: validationMessageKey
                        ),
                        lineWidth: 1.5
                    )
            )
    }

    @ViewBuilder
    private func pathActionControls(
        buttonTitle: LocalizedStringKey,
        allowedExtensions: [String]?,
        detectedPaths: [String],
        selectPath: @escaping (String) -> Void
    ) -> some View {
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

    private func pathRowBorderColor(isHighlighted: Bool, validationMessageKey: String?) -> Color {
        if let validationMessageKey {
            return validationColor(for: validationMessageKey).opacity(0.72)
        }

        return isHighlighted ? Color.accentColor.opacity(0.6) : .clear
    }

    private func validationColor(for messageKey: String) -> Color {
        switch messageKey {
        case "validation.port.unavailable":
            return .yellow
        default:
            return .red
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

    private func pathCaption(_ path: String) -> String {
        let name = URL(fileURLWithPath: path).lastPathComponent
        guard !name.isEmpty else {
            return path
        }

        return name
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
        case .qwen36MTPM4Max:
            return "preset.description.qwen36_mtp_m4max"
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
            return .yellow
        case .unknown:
            return .secondary
        }
    }
}
