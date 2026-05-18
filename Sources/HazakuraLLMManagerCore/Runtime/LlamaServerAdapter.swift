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
            "--host", config.host,
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

    public func endpoint(config: RuntimeConfiguration) -> RuntimeEndpoint {
        RuntimeEndpoint(
            apiBaseURL: URL(string: config.apiBaseURL)!,
            healthCheckURL: URL(string: config.healthCheckURL)
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

        if config.contextSize <= 0 {
            throw RuntimeAdapterError.invalidContextSize(config.contextSize)
        }

        _ = try optionalPositiveInt(config.threads, optionName: "threads")
        _ = try optionalNonNegativeInt(config.gpuLayers, optionName: "GPU layers")
        _ = try CommandLineArgumentTokenizer.tokenize(config.additionalArguments)
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

public enum RuntimeAdapterError: Error, Equatable, LocalizedError {
    case missingRuntimePath
    case missingModelPath
    case unsupportedModelType(String)
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
