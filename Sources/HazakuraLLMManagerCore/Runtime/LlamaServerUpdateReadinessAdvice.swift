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
                detail: "Run Check Runtime to capture local version and --help option evidence before any guarded update plan."
            )
        }

        guard capabilityResult.hasCompleteUpdatePlanningEvidence else {
            return LlamaServerUpdateReadinessAdvice(
                readiness: .capabilityEvidenceIncomplete,
                title: "Update dry-run: capability evidence incomplete",
                detail: capabilityResult.incompleteUpdatePlanningEvidenceDetail
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

    var incompleteUpdatePlanningEvidenceDetail: String {
        var missingEvidence: [String] = []

        if !versionCheck.completedSuccessfully || capabilities.versionSummary == nil {
            missingEvidence.append(versionEvidenceGap)
        }

        if !helpCheck.completedSuccessfully || capabilities.supportedOptions.isEmpty {
            missingEvidence.append(helpEvidenceGap)
        }

        let gapSummary = missingEvidence.joined(separator: " and ")
        return "Lantern detected the runtime source, but \(gapSummary). No update plan should be prepared yet."
    }

    private var versionEvidenceGap: String {
        if versionCheck.didTimeOut {
            return "the --version check timed out"
        }

        if let errorDescription = versionCheck.errorDescription {
            return "the --version check failed: \(errorDescription)"
        }

        if let terminationStatus = versionCheck.terminationStatus, terminationStatus != 0 {
            return "the --version check exited with status \(terminationStatus)"
        }

        return "the version summary is unavailable"
    }

    private var helpEvidenceGap: String {
        if helpCheck.didTimeOut {
            return "the --help check timed out"
        }

        if let errorDescription = helpCheck.errorDescription {
            return "the --help check failed: \(errorDescription)"
        }

        if let terminationStatus = helpCheck.terminationStatus, terminationStatus != 0 {
            return "the --help check exited with status \(terminationStatus)"
        }

        return "the --help option list is unavailable"
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
