import Darwin
import Foundation

public struct LlamaServerRuntimeCapabilities: Equatable, Sendable {
    public let versionSummary: String?
    public let supportedOptions: Set<String>

    public init(versionSummary: String?, supportedOptions: Set<String>) {
        self.versionSummary = versionSummary
        self.supportedOptions = supportedOptions
    }

    public static func parse(versionOutput: String?, helpOutput: String?) -> LlamaServerRuntimeCapabilities {
        LlamaServerRuntimeCapabilities(
            versionSummary: parseVersionSummary(from: versionOutput),
            supportedOptions: parseSupportedOptions(from: helpOutput)
        )
    }

    public func supports(option: String) -> Bool {
        supportedOptions.contains(Self.normalizedOption(option))
    }

    public func unsupportedOptions(for preset: LlamaServerPreset) -> [String] {
        preset.requiredRuntimeOptions.filter { !supports(option: $0) }
    }

    private static func parseVersionSummary(from output: String?) -> String? {
        output?
            .components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .first { !$0.isEmpty }
    }

    private static func parseSupportedOptions(from output: String?) -> Set<String> {
        guard let output else {
            return []
        }

        let tokens = output.components(separatedBy: .whitespacesAndNewlines)
        return Set(tokens.compactMap(optionToken))
    }

    private static func optionToken(_ rawToken: String) -> String? {
        var token = rawToken.trimmingCharacters(in: .whitespacesAndNewlines)
        token = token.trimmingCharacters(in: CharacterSet(charactersIn: "[](),:;"))

        if let equalsIndex = token.firstIndex(of: "=") {
            token = String(token[..<equalsIndex])
        }

        token = token.trimmingCharacters(in: CharacterSet(charactersIn: "[](),:;"))
        guard token.hasPrefix("-"),
              token.contains(where: { $0 != "-" }) else {
            return nil
        }

        return normalizedOption(token)
    }

    private static func normalizedOption(_ option: String) -> String {
        option.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

public struct LlamaServerCapabilityCommandResult: Equatable, Sendable {
    public let output: String
    public let terminationStatus: Int32?
    public let didTimeOut: Bool
    public let errorDescription: String?

    public init(
        output: String,
        terminationStatus: Int32?,
        didTimeOut: Bool,
        errorDescription: String?
    ) {
        self.output = output
        self.terminationStatus = terminationStatus
        self.didTimeOut = didTimeOut
        self.errorDescription = errorDescription
    }

    public var completedSuccessfully: Bool {
        didTimeOut == false && terminationStatus == 0 && errorDescription == nil
    }
}

public struct LlamaServerPresetCompatibilityNote: Equatable, Sendable {
    public enum Severity: Equatable, Sendable {
        case supported
        case warning
        case unknown
    }

    public let severity: Severity
    public let title: String
    public let detail: String

    public init(severity: Severity, title: String, detail: String) {
        self.severity = severity
        self.title = title
        self.detail = detail
    }
}

public struct LlamaServerCapabilityProbeResult: Equatable, Sendable {
    public let versionCheck: LlamaServerCapabilityCommandResult
    public let helpCheck: LlamaServerCapabilityCommandResult
    public let capabilities: LlamaServerRuntimeCapabilities

    public init(
        versionCheck: LlamaServerCapabilityCommandResult,
        helpCheck: LlamaServerCapabilityCommandResult,
        capabilities: LlamaServerRuntimeCapabilities
    ) {
        self.versionCheck = versionCheck
        self.helpCheck = helpCheck
        self.capabilities = capabilities
    }

    public func presetCompatibilityNote(for preset: LlamaServerPreset) -> LlamaServerPresetCompatibilityNote {
        let requiredOptions = preset.requiredRuntimeOptions
        guard !requiredOptions.isEmpty else {
            return LlamaServerPresetCompatibilityNote(
                severity: .supported,
                title: "Preset adds no extra runtime options",
                detail: "The selected preset changes visible settings without adding option flags."
            )
        }

        guard helpCheck.completedSuccessfully, !capabilities.supportedOptions.isEmpty else {
            return LlamaServerPresetCompatibilityNote(
                severity: .unknown,
                title: "Runtime option support is unknown",
                detail: capabilityCheckFailureDetail
            )
        }

        let unsupportedOptions = capabilities.unsupportedOptions(for: preset)
        guard !unsupportedOptions.isEmpty else {
            return LlamaServerPresetCompatibilityNote(
                severity: .supported,
                title: "Preset options are listed by this runtime",
                detail: "The selected runtime help includes \(requiredOptions.joined(separator: ", "))."
            )
        }

        return LlamaServerPresetCompatibilityNote(
            severity: .warning,
            title: "Preset options may be unsupported",
            detail: "The selected runtime help does not list \(unsupportedOptions.joined(separator: ", ")). Review the command preview before launch."
        )
    }

    private var capabilityCheckFailureDetail: String {
        if helpCheck.didTimeOut {
            return "The timeout-bounded --help check did not finish, so Lantern will not infer option support."
        }

        if let errorDescription = helpCheck.errorDescription {
            return "The local --help check failed: \(errorDescription)"
        }

        if let terminationStatus = helpCheck.terminationStatus, terminationStatus != 0 {
            return "The local --help check exited with status \(terminationStatus), so Lantern will not infer option support."
        }

        return "The local --help check returned no option list, so Lantern will keep preset arguments visible."
    }
}

public protocol LlamaServerCapabilityProbing: Sendable {
    func probe(executablePath: String) -> LlamaServerCapabilityProbeResult
}

public struct LlamaServerCapabilityProbe: LlamaServerCapabilityProbing, Sendable {
    public let timeout: TimeInterval

    public init(timeout: TimeInterval = 8) {
        self.timeout = timeout
    }

    public func probe(executablePath: String) -> LlamaServerCapabilityProbeResult {
        let versionCheck = run(executablePath: executablePath, arguments: ["--version"])
        let helpCheck = run(executablePath: executablePath, arguments: ["--help"])
        let capabilities = LlamaServerRuntimeCapabilities.parse(
            versionOutput: versionCheck.output,
            helpOutput: helpCheck.output
        )

        return LlamaServerCapabilityProbeResult(
            versionCheck: versionCheck,
            helpCheck: helpCheck,
            capabilities: capabilities
        )
    }

    private func run(executablePath: String, arguments: [String]) -> LlamaServerCapabilityCommandResult {
        let process = Process()
        let outputPipe = Pipe()
        let group = DispatchGroup()

        process.executableURL = URL(fileURLWithPath: executablePath)
        process.arguments = arguments
        process.standardOutput = outputPipe
        process.standardError = outputPipe

        do {
            try process.run()
        } catch {
            return LlamaServerCapabilityCommandResult(
                output: "",
                terminationStatus: nil,
                didTimeOut: false,
                errorDescription: error.localizedDescription
            )
        }

        group.enter()
        DispatchQueue.global(qos: .utility).async {
            process.waitUntilExit()
            group.leave()
        }

        let waitResult = group.wait(timeout: .now() + timeout)
        let didTimeOut = waitResult == .timedOut
        if didTimeOut {
            process.terminate()
            if group.wait(timeout: .now() + 0.5) == .timedOut {
                kill(process.processIdentifier, SIGKILL)
                group.wait()
            }
        }

        let output = String(
            data: outputPipe.fileHandleForReading.readDataToEndOfFile(),
            encoding: .utf8
        ) ?? ""

        return LlamaServerCapabilityCommandResult(
            output: output,
            terminationStatus: process.terminationStatus,
            didTimeOut: didTimeOut,
            errorDescription: nil
        )
    }
}

public extension LlamaServerPreset {
    var requiredRuntimeOptions: [String] {
        additionalArguments.filter { $0.hasPrefix("-") }
    }
}
