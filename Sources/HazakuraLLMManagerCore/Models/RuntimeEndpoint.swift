import Foundation

public struct RuntimeEndpoint: Equatable, Sendable {
    public var apiBaseURL: URL
    public var healthCheckURL: URL?
    public var healthCheckTimeoutSeconds: Int
    public var modelID: String
    public var modelName: String
    public var apiKey: String?

    public init(
        apiBaseURL: URL,
        healthCheckURL: URL?,
        healthCheckTimeoutSeconds: Int = 5,
        modelID: String = "local",
        modelName: String = "local model",
        apiKey: String? = nil
    ) {
        self.apiBaseURL = apiBaseURL
        self.healthCheckURL = healthCheckURL
        self.healthCheckTimeoutSeconds = healthCheckTimeoutSeconds
        self.modelID = modelID
        self.modelName = modelName
        self.apiKey = apiKey
    }

    public var apiBaseURLString: String {
        apiBaseURL.absoluteString
    }

    public var environmentSnippet: String {
        var lines = [
            "OPENAI_BASE_URL=\(ShellQuoter.quote(apiBaseURLString))",
            "OPENAI_MODEL_ID=\(ShellQuoter.quote(modelID))"
        ]

        if let apiKey, !apiKey.isEmpty {
            lines.append("OPENAI_API_KEY=\(ShellQuoter.quote(apiKey))")
        }

        return lines.joined(separator: "\n")
    }

    public var endpointHealthRequest: EndpointHealthRequest? {
        healthCheckURL.map {
            EndpointHealthRequest(
                healthURL: $0.absoluteString,
                timeoutSeconds: healthCheckTimeoutSeconds
            )
        }
    }

    public var endpointHealthCurlCommand: String? {
        endpointHealthRequest?.curlCommand
    }

    public var aiMobileSmokeRequest: ClientSmokeRequest {
        ClientSmokeRequest(baseURL: apiBaseURLString, apiKey: apiKey, model: modelID)
    }

    public var aiMobileSmokeCurlCommand: String {
        aiMobileSmokeRequest.curlCommand
    }
}
