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

    public var openCodeConfigSnippet: String {
        let document = OpenCodeConfigDocument(
            provider: [
                "lantern": OpenCodeProvider(
                    name: "Hazakura Lantern (local)",
                    options: OpenCodeProviderOptions(baseURL: apiBaseURLString),
                    models: [
                        modelID: OpenCodeModel(name: modelName)
                    ]
                )
            ],
            model: "lantern/\(modelID)"
        )

        return prettyPrintedJSON(document)
    }

    public var hazakuraNoteConnectionSnippet: String {
        let document = HazakuraNoteConnectionDocument(
            baseURL: apiBaseURLString,
            model: modelID,
            modelName: modelName,
            apiKeyRequired: apiKey?.isEmpty == false
        )

        return prettyPrintedJSON(document)
    }

    public var connectionSnapshotSnippet: String {
        let document = ConnectionSnapshotDocument(
            baseURL: apiBaseURLString,
            modelID: modelID,
            modelName: modelName,
            healthCheckURL: healthCheckURL?.absoluteString,
            apiKeyRequired: apiKey?.isEmpty == false
        )

        return prettyPrintedJSON(document)
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

    private func prettyPrintedJSON<T: Encodable>(_ value: T) -> String {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]

        guard let data = try? encoder.encode(value),
              let string = String(data: data, encoding: .utf8)
        else {
            return "{}"
        }

        return string
    }
}

private struct OpenCodeConfigDocument: Encodable {
    var schema = "https://opencode.ai/config.json"
    var provider: [String: OpenCodeProvider]
    var model: String

    enum CodingKeys: String, CodingKey {
        case schema = "$schema"
        case model
        case provider
    }
}

private struct OpenCodeProvider: Encodable {
    var npm = "@ai-sdk/openai-compatible"
    var name: String
    var options: OpenCodeProviderOptions
    var models: [String: OpenCodeModel]
}

private struct OpenCodeProviderOptions: Encodable {
    var baseURL: String
}

private struct OpenCodeModel: Encodable {
    var name: String
}

private struct HazakuraNoteConnectionDocument: Encodable {
    var schemaVersion = 1
    var provider = "openai-compatible"
    var baseURL: String
    var model: String
    var modelName: String
    var apiKeyRequired: Bool
}

private struct ConnectionSnapshotDocument: Encodable {
    var schemaVersion = 1
    var source = "hazakura-lantern"
    var api = "openai-compatible"
    var baseURL: String
    var modelID: String
    var modelName: String
    var healthCheckURL: String?
    var apiKeyRequired: Bool
}
