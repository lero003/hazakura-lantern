import Foundation

public struct LlamaServerUpdateReadinessAdvice: Equatable, Sendable {
    public enum Readiness: Equatable, Sendable {
        case needsCapabilityCheck
        case capabilityEvidenceIncomplete
        case planningEvidenceReady
        case manualOnly
    }

    public let readiness: Readiness
    public let title: String
    public let detail: String

    public init(readiness: Readiness, title: String, detail: String) {
        self.readiness = readiness
        self.title = title
        self.detail = detail
    }

    public static func evaluate(
        executablePath: String,
        capabilityResult: LlamaServerCapabilityProbeResult?
    ) -> LlamaServerUpdateReadinessAdvice? {
        guard let sourceAdvice = LlamaServerInstallSourceAdvice.classify(executablePath: executablePath) else {
            return nil
        }

        if sourceAdvice.source == .manualPath {
            return LlamaServerUpdateReadinessAdvice(
                readiness: .manualOnly,
                title: "Update dry-run: manual path",
                detail: "Lantern cannot infer a safe updater for this binary. Keep replacement manual, then re-check version and options before launch."
            )
        }

        guard let capabilityResult else {
            return LlamaServerUpdateReadinessAdvice(
                readiness: .needsCapabilityCheck,
                title: "Update dry-run: check runtime first",
                detail: "Before any guarded update plan, Lantern needs the selected path source plus a local version and --help capability check."
            )
        }

        guard capabilityResult.hasCompleteUpdatePlanningEvidence else {
            return LlamaServerUpdateReadinessAdvice(
                readiness: .capabilityEvidenceIncomplete,
                title: "Update dry-run: capability evidence incomplete",
                detail: "Lantern detected the runtime source, but version or option support is incomplete. No update plan should be prepared yet."
            )
        }

        return LlamaServerUpdateReadinessAdvice(
            readiness: .planningEvidenceReady,
            title: "Update dry-run: planning evidence ready",
            detail: sourceAdvice.source.updatePlanningDetail(versionSummary: capabilityResult.capabilities.versionSummary)
        )
    }
}

private extension LlamaServerCapabilityProbeResult {
    var hasCompleteUpdatePlanningEvidence: Bool {
        versionCheck.completedSuccessfully
            && helpCheck.completedSuccessfully
            && capabilities.versionSummary != nil
            && !capabilities.supportedOptions.isEmpty
    }
}

private extension LlamaServerInstallSourceAdvice.Source {
    func updatePlanningDetail(versionSummary: String?) -> String {
        let version = versionSummary ?? "the selected runtime"

        switch self {
        case .homebrew:
            return "Lantern has \(version), path source, and option evidence. A future plan must show the exact Homebrew command, require confirmation, and re-check after update."
        case .macPorts:
            return "Lantern has \(version), path source, and option evidence. A future plan must show the exact MacPorts command, require confirmation, and re-check after update."
        case .sourceCheckout:
            return "Lantern has \(version), path source, and option evidence. A future plan must show the exact checkout and build steps, require confirmation, and re-check after update."
        case .manualPath:
            return "Manual paths stay advisory."
        }
    }
}
