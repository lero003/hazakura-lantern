import Darwin
import Foundation

public struct LlamaServerAdapter: RuntimeAdapter {
    public let id = "llama-server"
    public let displayName = "llama.cpp server"
    public let supportedModelTypes = ["gguf"]

    public init() {}

    public func buildLaunchCommand(config: RuntimeConfiguration) throws -> LaunchCommand {
        try validate(config: config)

        var arguments = [
            "-m", config.modelPath,
            "--host", launchHost(config.host),
            "--port", String(config.port),
            "-c", String(config.contextSize)
        ]

        if let threads = try optionalPositiveInt(config.threads, optionName: "threads") {
            arguments.append(contentsOf: ["-t", String(threads)])
        }

        if let gpuLayers = try optionalNonNegativeInt(config.gpuLayers, optionName: "GPU layers") {
            arguments.append(contentsOf: ["-ngl", String(gpuLayers)])
        }

        arguments.append(contentsOf: try CommandLineArgumentTokenizer.tokenize(config.additionalArguments))

        return LaunchCommand(
            executablePath: config.runtimeExecutablePath,
            arguments: arguments
        )
    }

    public func endpoint(config: RuntimeConfiguration) throws -> RuntimeEndpoint {
        try validateEndpointConfiguration(config)

        guard let apiBaseURL = URL(string: config.apiBaseURL) else {
            throw RuntimeAdapterError.invalidHost(config.host)
        }

        guard let healthCheckURL = URL(string: config.healthCheckURL) else {
            throw RuntimeAdapterError.invalidPort(config.port)
        }

        return RuntimeEndpoint(
            apiBaseURL: apiBaseURL,
            healthCheckURL: healthCheckURL
        )
    }

    public func validate(config: RuntimeConfiguration) throws {
        if config.runtimeExecutablePath.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            throw RuntimeAdapterError.missingRuntimePath
        }

        if config.modelPath.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            throw RuntimeAdapterError.missingModelPath
        }

        let modelExtension = URL(fileURLWithPath: config.modelPath.trimmingCharacters(in: .whitespacesAndNewlines))
            .pathExtension
            .lowercased()
        if !supportedModelTypes.contains(modelExtension) {
            throw RuntimeAdapterError.unsupportedModelType(config.modelPath)
        }

        if !(1...65535).contains(config.port) {
            throw RuntimeAdapterError.invalidPort(config.port)
        }

        try validateEndpointConfiguration(config)

        if config.contextSize <= 0 {
            throw RuntimeAdapterError.invalidContextSize(config.contextSize)
        }

        _ = try optionalPositiveInt(config.threads, optionName: "threads")
        _ = try optionalNonNegativeInt(config.gpuLayers, optionName: "GPU layers")
        _ = try CommandLineArgumentTokenizer.tokenize(config.additionalArguments)
    }

    public func validateLaunchPreconditions(config: RuntimeConfiguration, fileManager: FileManager) throws {
        try validate(config: config)

        var isRuntimeDirectory = ObjCBool(false)
        guard fileManager.fileExists(atPath: config.runtimeExecutablePath, isDirectory: &isRuntimeDirectory) else {
            throw LaunchPreflightError.runtimeFileMissing(config.runtimeExecutablePath)
        }

        guard !isRuntimeDirectory.boolValue else {
            throw LaunchPreflightError.runtimePathIsDirectory(config.runtimeExecutablePath)
        }

        guard fileManager.isExecutableFile(atPath: config.runtimeExecutablePath) else {
            throw LaunchPreflightError.runtimeNotExecutable(config.runtimeExecutablePath)
        }

        var isModelDirectory = ObjCBool(false)
        guard fileManager.fileExists(atPath: config.modelPath, isDirectory: &isModelDirectory) else {
            throw LaunchPreflightError.modelFileMissing(config.modelPath)
        }

        guard !isModelDirectory.boolValue else {
            throw LaunchPreflightError.modelPathIsDirectory(config.modelPath)
        }
    }

    public func describeLaunchProcessFailure(_ error: Error, command: LaunchCommand) -> String {
        LaunchProcessFailureMessage.describe(
            error,
            command: command,
            runtimeExecutableName: "llama-server binary",
            fallbackRecoveryHint: "Check the selected llama-server binary, model, and launch options, then try again."
        )
    }

    private func validateEndpointConfiguration(_ config: RuntimeConfiguration) throws {
        if !(1...65535).contains(config.port) {
            throw RuntimeAdapterError.invalidPort(config.port)
        }

        let trimmedHost = config.host.trimmingCharacters(in: .whitespacesAndNewlines)
        let invalidCharacters = CharacterSet.whitespacesAndNewlines
            .union(CharacterSet(charactersIn: "/\\?#@%"))

        if trimmedHost.rangeOfCharacter(from: invalidCharacters) != nil {
            throw RuntimeAdapterError.invalidHost(config.host)
        }

        guard isValidHostShape(trimmedHost) else {
            throw RuntimeAdapterError.invalidHost(config.host)
        }
    }

    private func launchHost(_ host: String) -> String {
        let trimmedHost = host.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmedHost.hasPrefix("[") && trimmedHost.hasSuffix("]") {
            return String(trimmedHost.dropFirst().dropLast())
        }

        return trimmedHost.isEmpty ? RuntimeConfiguration.defaultValue.host : trimmedHost
    }

    private func isValidHostShape(_ host: String) -> Bool {
        guard !host.isEmpty else {
            return true
        }

        if host.contains("[") || host.contains("]") {
            guard host.hasPrefix("["),
                  host.hasSuffix("]") else {
                return false
            }

            let unwrappedHost = String(host.dropFirst().dropLast())
            return isIPv6Literal(unwrappedHost)
        }

        if host.contains(":") {
            return isIPv6Literal(host)
        }

        if isIPv4AddressShape(host) {
            return isIPv4Literal(host)
        }

        return isDNSName(host)
    }

    private func isIPv4AddressShape(_ host: String) -> Bool {
        let labels = host.split(separator: ".", omittingEmptySubsequences: false)
        guard labels.count == 4 else {
            return false
        }

        return labels.allSatisfy { label in
            !label.isEmpty && label.utf8.allSatisfy { byte in
                (CharacterCode.zero...CharacterCode.nine).contains(byte)
            }
        }
    }

    private func isIPv4Literal(_ host: String) -> Bool {
        var address = in_addr()
        return host.withCString { inet_pton(AF_INET, $0, &address) } == 1
    }

    private func isDNSName(_ host: String) -> Bool {
        guard !host.isEmpty, host.utf8.count <= 253 else {
            return false
        }

        return host.split(separator: ".", omittingEmptySubsequences: false)
            .allSatisfy(isValidDNSLabel)
    }

    private func isValidDNSLabel(_ label: Substring) -> Bool {
        guard let firstByte = label.utf8.first,
              let lastByte = label.utf8.last,
              !label.isEmpty,
              label.utf8.count <= 63,
              isASCIILetterOrDigit(firstByte),
              isASCIILetterOrDigit(lastByte) else {
            return false
        }

        return label.utf8.allSatisfy { byte in
            isASCIILetterOrDigit(byte) || byte == CharacterCode.hyphen
        }
    }

    private func isASCIILetterOrDigit(_ byte: UInt8) -> Bool {
        (CharacterCode.zero...CharacterCode.nine).contains(byte)
            || (CharacterCode.uppercaseA...CharacterCode.uppercaseZ).contains(byte)
            || (CharacterCode.lowercaseA...CharacterCode.lowercaseZ).contains(byte)
    }

    private func isIPv6Literal(_ host: String) -> Bool {
        var address = in6_addr()
        return host.withCString { inet_pton(AF_INET6, $0, &address) } == 1
    }

    private func optionalPositiveInt(_ value: String, optionName: String) throws -> Int? {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty || trimmed.lowercased() == "auto" {
            return nil
        }

        guard let intValue = Int(trimmed), intValue > 0 else {
            throw RuntimeAdapterError.invalidNumericOption(name: optionName, value: value)
        }

        return intValue
    }

    private func optionalNonNegativeInt(_ value: String, optionName: String) throws -> Int? {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty || trimmed.lowercased() == "auto" {
            return nil
        }

        guard let intValue = Int(trimmed), intValue >= 0 else {
            throw RuntimeAdapterError.invalidNonNegativeNumericOption(name: optionName, value: value)
        }

        return intValue
    }
}

private enum CharacterCode {
    static let hyphen = UInt8(ascii: "-")
    static let zero = UInt8(ascii: "0")
    static let nine = UInt8(ascii: "9")
    static let uppercaseA = UInt8(ascii: "A")
    static let uppercaseZ = UInt8(ascii: "Z")
    static let lowercaseA = UInt8(ascii: "a")
    static let lowercaseZ = UInt8(ascii: "z")
}

public enum RuntimeAdapterError: Error, Equatable, LocalizedError {
    case missingRuntimePath
    case missingModelPath
    case unsupportedModelType(String)
    case invalidHost(String)
    case invalidPort(Int)
    case invalidContextSize(Int)
    case invalidNumericOption(name: String, value: String)
    case invalidNonNegativeNumericOption(name: String, value: String)

    public var errorDescription: String? {
        switch self {
        case .missingRuntimePath:
            "Choose a llama-server executable before starting."
        case .missingModelPath:
            "Choose a .gguf model file before starting."
        case .unsupportedModelType(let path):
            "Model file must be a .gguf file before launch. Current path: \(path)."
        case .invalidHost(let host):
            "Host must be blank, localhost, an IP address, or a DNS name before launch or endpoint copy. Current value: \(host)."
        case .invalidPort(let port):
            "Port must be between 1 and 65535 before launch. Current value: \(port)."
        case .invalidContextSize(let contextSize):
            "Context size must be greater than zero before launch. Current value: \(contextSize)."
        case .invalidNumericOption(let name, let value):
            "\(name) must be a positive integer or auto before launch. Current value: \(value)."
        case .invalidNonNegativeNumericOption(let name, let value):
            "\(name) must be a non-negative integer or auto before launch. Current value: \(value)."
        }
    }
}
