import Foundation
import SwiftUI
import HazakuraLLMManagerCore

struct ConfigurationView: View {
    @ObservedObject var controller: ServerController
    @Environment(\.locale) private var locale
    @State private var selectedPresetIntent: LlamaServerPresetIntent = .standard
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
                        detectedPaths: controller.detectedRuntimeExecutablePaths,
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
                        detectedPaths: [],
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

                            Text(LocalizedStringKey(presetDescriptionKey(for: selectedPresetIntent)))
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

                            if let advice = localizedUpdateReadinessAdvice {
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

                            VStack(alignment: .leading, spacing: 6) {
                                HStack(spacing: 8) {
                                    Picker("Runtime Update Target", selection: $controller.runtimeUpdateCheckTarget) {
                                        ForEach(RuntimeUpdateCheckTarget.allCases) { target in
                                            Text(target.displayName)
                                                .tag(target)
                                        }
                                    }
                                    .labelsHidden()
                                    .pickerStyle(.menu)
                                    .frame(width: 150)

                                    Button {
                                        controller.checkRuntimeUpdates()
                                    } label: {
                                        Label("Check for Updates", systemImage: "arrow.down.circle")
                                    }
                                    .buttonStyle(SecondaryButtonStyle())
                                    .disabled(controller.isRuntimeUpdateCheckRunning)

                                    if controller.isRuntimeUpdateCheckRunning {
                                        ProgressView()
                                            .controlSize(.small)
                                    }
                                }

                                if let message = localizedRuntimeUpdateDisplayMessage {
                                    Label(message, systemImage: "arrow.down.circle")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                        .fixedSize(horizontal: false, vertical: true)
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

    private func pathMenuLabel(_ path: String) -> String {
        let name = URL(fileURLWithPath: path).lastPathComponent
        guard !name.isEmpty else {
            return path
        }

        return "\(name) - \(path)"
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

    private var localizedRuntimeUpdateDisplayMessage: String? {
        if let availability = controller.runtimeUpdateAvailability {
            return "\(runtimeUpdateAvailabilityTitle(availability)). \(runtimeUpdateAvailabilityDetail(availability))"
        }

        guard let message = controller.runtimeUpdateAvailabilityMessage else {
            return nil
        }

        switch message {
        case .targetChanged:
            return localized("runtime_update.target_changed")
        case .failed(let errorDescription):
            return localized("runtime_update.failed", errorDescription)
        }
    }

    private var localizedUpdateReadinessAdvice: (title: String, detail: String)? {
        guard let advice = controller.runtimeUpdateReadinessAdvice else {
            return nil
        }

        switch advice.readiness {
        case .needsCapabilityCheck:
            return (
                localized("runtime_update_readiness.needs_capability.title"),
                localized("runtime_update_readiness.needs_capability.detail")
            )
        case .capabilityEvidenceIncomplete:
            let gapSummary = controller.runtimeCapabilityProbeResult.map(localizedIncompleteUpdateEvidenceSummary) ?? localized("runtime_update_readiness.evidence.version_unavailable")
            return (
                localized("runtime_update_readiness.incomplete.title"),
                localized("runtime_update_readiness.incomplete.detail", gapSummary)
            )
        case .planningEvidenceReady:
            let versionSummary = controller.runtimeCapabilityProbeResult?.capabilities.versionSummary ?? localized("runtime_update_readiness.selected_runtime")
            return (
                localized("runtime_update_readiness.ready.title"),
                localizedPlanningEvidenceReadyDetail(versionSummary: versionSummary)
            )
        case .manualOnly:
            return (
                localized("runtime_update_readiness.manual.title"),
                localized("runtime_update_readiness.manual.detail")
            )
        }
    }

    private func localizedIncompleteUpdateEvidenceSummary(_ result: LlamaServerCapabilityProbeResult) -> String {
        var missingEvidence: [String] = []

        if !result.versionCheck.completedSuccessfully || result.capabilities.versionSummary == nil {
            missingEvidence.append(localizedVersionEvidenceGap(result.versionCheck))
        }

        if !result.helpCheck.completedSuccessfully || result.capabilities.supportedOptions.isEmpty {
            missingEvidence.append(localizedHelpEvidenceGap(result.helpCheck))
        }

        return missingEvidence.joined(separator: localized("runtime_update_readiness.evidence.separator"))
    }

    private func localizedVersionEvidenceGap(_ check: LlamaServerCapabilityCommandResult) -> String {
        if check.didTimeOut {
            return localized("runtime_update_readiness.evidence.version_timeout")
        }

        if let errorDescription = check.errorDescription {
            return localized("runtime_update_readiness.evidence.version_failed", errorDescription)
        }

        if let terminationStatus = check.terminationStatus, terminationStatus != 0 {
            return localized("runtime_update_readiness.evidence.version_status", Int(terminationStatus))
        }

        return localized("runtime_update_readiness.evidence.version_unavailable")
    }

    private func localizedHelpEvidenceGap(_ check: LlamaServerCapabilityCommandResult) -> String {
        if check.didTimeOut {
            return localized("runtime_update_readiness.evidence.help_timeout")
        }

        if let errorDescription = check.errorDescription {
            return localized("runtime_update_readiness.evidence.help_failed", errorDescription)
        }

        if let terminationStatus = check.terminationStatus, terminationStatus != 0 {
            return localized("runtime_update_readiness.evidence.help_status", Int(terminationStatus))
        }

        return localized("runtime_update_readiness.evidence.help_unavailable")
    }

    private func localizedPlanningEvidenceReadyDetail(versionSummary: String) -> String {
        switch controller.runtimeInstallSourceAdvice?.source {
        case .homebrew:
            localized("runtime_update_readiness.ready.homebrew.detail", versionSummary)
        case .macPorts:
            localized("runtime_update_readiness.ready.macports.detail", versionSummary)
        case .sourceCheckout:
            localized("runtime_update_readiness.ready.source_checkout.detail", versionSummary)
        case .manualPath, nil:
            localized("runtime_update_readiness.ready.detail", versionSummary)
        }
    }

    private func runtimeUpdateAvailabilityTitle(_ availability: RuntimeUpdateAvailability) -> String {
        switch availability.comparison {
        case .updateAvailable:
            localized("runtime_update.available.title", availability.latestRelease.tagName)
        case .currentOrNewer:
            localized("runtime_update.current.title", availability.latestRelease.tagName)
        case .unknownLocalVersion:
            localized("runtime_update.unknown_local.title", availability.target.displayName, availability.latestRelease.tagName)
        case .unknownLatestVersion:
            localized("runtime_update.unknown_latest.title", availability.target.displayName)
        }
    }

    private func runtimeUpdateAvailabilityDetail(_ availability: RuntimeUpdateAvailability) -> String {
        switch availability.comparison {
        case .updateAvailable:
            localized("runtime_update.available.detail", availability.latestRelease.tagName)
        case .currentOrNewer:
            localized("runtime_update.current.detail")
        case .unknownLocalVersion:
            localized("runtime_update.unknown_local.detail")
        case .unknownLatestVersion:
            localized("runtime_update.unknown_latest.detail")
        }
    }

    private func localized(_ key: String, _ arguments: CVarArg...) -> String {
        let format = String(
            localized: String.LocalizationValue(key),
            bundle: .module,
            locale: locale
        )

        guard !arguments.isEmpty else {
            return format
        }

        return String(format: format, locale: locale, arguments: arguments)
    }
}
