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
}
