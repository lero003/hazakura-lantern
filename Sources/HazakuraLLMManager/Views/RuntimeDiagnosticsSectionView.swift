import SwiftUI
import HazakuraLLMManagerCore

struct RuntimeDiagnosticsSectionView: View {
    @ObservedObject var controller: ServerController
    @Environment(\.locale) private var locale
    @State private var isRuntimeArgumentsExpanded = false

    var body: some View {
        GridRow {
            VStack(alignment: .leading, spacing: 14) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Runtime Diagnostics")
                        .font(.headline)

                    Text("Check local runtime version, supported options, and advisory update metadata.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                VStack(alignment: .leading, spacing: 10) {
                    Text("Runtime Check")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.secondary)

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

                        Button {
                            if runtimeHelpOutput == nil {
                                isRuntimeArgumentsExpanded = true
                                controller.checkRuntimeCapabilities()
                            } else {
                                withAnimation(.easeInOut(duration: 0.15)) {
                                    isRuntimeArgumentsExpanded.toggle()
                                }
                            }
                        } label: {
                            Label(
                                LocalizedStringKey(runtimeArgumentsButtonTitle),
                                systemImage: "list.bullet.rectangle"
                            )
                        }
                        .buttonStyle(SecondaryButtonStyle())
                        .disabled(controller.isRuntimeCapabilityProbeRunning)
                    }

                    if let message = localizedRuntimeCapabilityProbeMessage {
                        Label(message, systemImage: "info.circle")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    if isRuntimeArgumentsExpanded {
                        runtimeArgumentsHelp
                            .padding(.top, 2)
                    }

                    if let advice = localizedRuntimeInstallSourceAdvice {
                        VStack(alignment: .leading, spacing: 3) {
                            Label(advice.title, systemImage: "arrow.triangle.2.circlepath.circle")
                                .font(.caption)
                                .foregroundStyle(.secondary)

                            Text(advice.detail)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .lineLimit(2)
                        }
                    }
                }

                Divider()
                    .opacity(0.5)
                    .padding(.vertical, 2)

                VStack(alignment: .leading, spacing: 10) {
                    Text("Runtime Update")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.secondary)

                    if let advice = localizedUpdateReadinessAdvice {
                        VStack(alignment: .leading, spacing: 3) {
                            Label(advice.title, systemImage: "checklist")
                                .font(.caption)
                                .foregroundStyle(.secondary)

                            Text(advice.detail)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .lineLimit(3)
                        }
                    }

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
            }
            .padding(.top, 6)
            .padding(.bottom, 10)
            .gridCellColumns(2)
        }
    }

    @ViewBuilder
    private var runtimeArgumentsHelp: some View {
        if let runtimeHelpOutput {
            VStack(alignment: .leading, spacing: 6) {
                Label("Runtime Arguments", systemImage: "terminal")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)

                ScrollView([.vertical, .horizontal]) {
                    Text(runtimeHelpOutput)
                        .font(.system(.caption2, design: .monospaced))
                        .foregroundStyle(.secondary)
                        .textSelection(.enabled)
                        .padding(10)
                }
                .frame(minHeight: 180, maxHeight: 280)
                .frame(maxWidth: 640, alignment: .leading)
                .background(.black.opacity(0.18), in: RoundedRectangle(cornerRadius: 8))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(.white.opacity(0.08), lineWidth: 1)
                )
            }
            .frame(maxWidth: 720, alignment: .leading)
        } else {
            Label("Run Check Runtime to load argument help.", systemImage: "info.circle")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private var runtimeHelpOutput: String? {
        guard let output = controller.runtimeCapabilityProbeResult?.helpCheck.output
            .trimmingCharacters(in: .whitespacesAndNewlines),
              !output.isEmpty
        else {
            return nil
        }

        return output
    }

    private var runtimeArgumentsButtonTitle: String {
        if runtimeHelpOutput == nil {
            "Load Runtime Arguments"
        } else if isRuntimeArgumentsExpanded {
            "Hide Runtime Arguments"
        } else {
            "Show Runtime Arguments"
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

    private var localizedRuntimeCapabilityProbeMessage: String? {
        guard let message = controller.runtimeCapabilityProbeMessage else {
            return nil
        }

        if let version = message.stripPrefix("Runtime: ") {
            return localized("runtime_probe.version", version)
        }

        switch message {
        case "Choose a llama-server executable before checking runtime options.":
            return localized("runtime_probe.choose_runtime")
        case "Runtime selection changed; check capabilities again.":
            return localized("runtime_probe.selection_changed")
        case "Runtime version unavailable.":
            return localized("runtime_probe.version_unavailable")
        default:
            return message
        }
    }

    private var localizedRuntimeInstallSourceAdvice: (title: String, detail: String)? {
        guard let advice = controller.runtimeInstallSourceAdvice else {
            return nil
        }

        switch advice.source {
        case .homebrew:
            return (
                localized("runtime_source.homebrew.title"),
                localized("runtime_source.homebrew.detail")
            )
        case .macPorts:
            return (
                localized("runtime_source.macports.title"),
                localized("runtime_source.macports.detail")
            )
        case .sourceCheckout:
            return (
                localized("runtime_source.source_checkout.title"),
                localized("runtime_source.source_checkout.detail")
            )
        case .manualPath:
            return (
                localized("runtime_source.manual.title"),
                localized("runtime_source.manual.detail")
            )
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

private extension String {
    func stripPrefix(_ prefix: String) -> String? {
        guard hasPrefix(prefix) else {
            return nil
        }

        return String(dropFirst(prefix.count))
    }
}
