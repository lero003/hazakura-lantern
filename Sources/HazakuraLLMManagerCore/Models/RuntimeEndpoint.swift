import Foundation

public struct RuntimeEndpoint: Equatable, Sendable {
    public var apiBaseURL: URL
    public var healthCheckURL: URL?
    public var healthCheckTimeoutSeconds: Int
    public var apiKey: String

    public init(
        apiBaseURL: URL,
        healthCheckURL: URL?,
        healthCheckTimeoutSeconds: Int = 5,
        apiKey: String = "local"
    ) {
        self.apiBaseURL = apiBaseURL
        self.healthCheckURL = healthCheckURL
        self.healthCheckTimeoutSeconds = healthCheckTimeoutSeconds
        self.apiKey = apiKey
    }

    public var apiBaseURLString: String {
        apiBaseURL.absoluteString
    }

    public var environmentSnippet: String {
        """
        OPENAI_BASE_URL=\(apiBaseURLString)
        OPENAI_API_KEY=\(apiKey)
        """
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
        ClientSmokeRequest(baseURL: apiBaseURLString, apiKey: apiKey)
    }

    public var aiMobileSmokeCurlCommand: String {
        aiMobileSmokeRequest.curlCommand
    }
}
