import Foundation

public struct RuntimeConfiguration: Codable, Equatable, Sendable {
    public var runtimeExecutablePath: String
    public var modelPath: String
    public var host: String
    public var port: Int
    public var contextSize: Int
    public var threads: String
    public var gpuLayers: String
    public var additionalArguments: String

    public init(
        runtimeExecutablePath: String,
        modelPath: String,
        host: String,
        port: Int,
        contextSize: Int,
        threads: String,
        gpuLayers: String,
        additionalArguments: String
    ) {
        self.runtimeExecutablePath = runtimeExecutablePath
        self.modelPath = modelPath
        self.host = host
        self.port = port
        self.contextSize = contextSize
        self.threads = threads
        self.gpuLayers = gpuLayers
        self.additionalArguments = additionalArguments
    }

    public static let defaultValue = RuntimeConfiguration(
        runtimeExecutablePath: "/usr/local/bin/llama-server",
        modelPath: "",
        host: "127.0.0.1",
        port: 1234,
        contextSize: 32768,
        threads: "auto",
        gpuLayers: "auto",
        additionalArguments: ""
    )

    public var clientHost: String {
        let trimmedHost = host.trimmingCharacters(in: .whitespacesAndNewlines)
        switch trimmedHost.lowercased() {
        case "", "127.0.0.1", "::1", "[::1]", "0.0.0.0", "::", "[::]":
            return "localhost"
        default:
            if trimmedHost.contains(":") && !trimmedHost.hasPrefix("[") {
                return "[\(trimmedHost)]"
            }

            return trimmedHost
        }
    }

    public var apiBaseURL: String {
        "http://\(clientHost):\(port)/v1"
    }

    public var environmentSnippet: String {
        """
        OPENAI_BASE_URL=\(apiBaseURL)
        OPENAI_API_KEY=local
        """
    }

    public var aiMobileSmokeRequest: ClientSmokeRequest {
        ClientSmokeRequest(baseURL: apiBaseURL)
    }

    public var aiMobileSmokeCurlCommand: String {
        aiMobileSmokeRequest.curlCommand
    }

    public var healthCheckURL: String {
        "http://localhost:\(port)/v1/models"
    }

    public var endpointHealthRequest: EndpointHealthRequest {
        EndpointHealthRequest(healthURL: healthCheckURL)
    }

    public var endpointHealthCurlCommand: String {
        endpointHealthRequest.curlCommand
    }

    public var launchSetupHint: String? {
        let missingRuntime = runtimeExecutablePath.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        let trimmedModelPath = modelPath.trimmingCharacters(in: .whitespacesAndNewlines)
        let missingModel = trimmedModelPath.isEmpty

        switch (missingRuntime, missingModel) {
        case (true, true):
            return "Choose a llama-server executable and .gguf model before starting."
        case (true, false):
            return "Choose a llama-server executable before starting."
        case (false, true):
            return "Choose a .gguf model before starting."
        case (false, false):
            let modelExtension = URL(fileURLWithPath: trimmedModelPath).pathExtension.lowercased()
            if modelExtension != "gguf" {
                return "Choose a .gguf model file before starting. Lantern does not convert or download models."
            }

            if !(1...65535).contains(port) {
                return "Choose a port between 1 and 65535 before starting."
            }

            if contextSize <= 0 {
                return "Choose a context size greater than zero before starting."
            }

            if !isAutoOrPositiveInteger(threads) {
                return "Set threads to auto or a positive integer before starting."
            }

            if !isAutoOrNonNegativeInteger(gpuLayers) {
                return "Set GPU layers to auto or a non-negative integer before starting."
            }

            do {
                _ = try CommandLineArgumentTokenizer.tokenize(additionalArguments)
            } catch {
                return "Fix Additional Args before starting: \(error.localizedDescription)"
            }

            return nil
        }
    }

    private func isAutoOrPositiveInteger(_ value: String) -> Bool {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty || trimmed.lowercased() == "auto" {
            return true
        }

        guard let intValue = Int(trimmed) else {
            return false
        }

        return intValue > 0
    }

    private func isAutoOrNonNegativeInteger(_ value: String) -> Bool {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty || trimmed.lowercased() == "auto" {
            return true
        }

        guard let intValue = Int(trimmed) else {
            return false
        }

        return intValue >= 0
    }
}
