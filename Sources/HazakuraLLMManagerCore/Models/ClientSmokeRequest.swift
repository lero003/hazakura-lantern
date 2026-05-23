import Foundation

public struct ClientSmokeRequest: Equatable, Sendable {
    public static let defaultUserText = "Hazakura AI Mobile runtime smoke. Reply with OK."
    public static let defaultTimeoutSeconds = 180
    public static let defaultMaxTokens = 2_048

    public var baseURL: String
    public var apiKey: String?
    public var model: String
    public var userText: String
    public var timeoutSeconds: Int
    public var maxTokens: Int

    public init(
        baseURL: String,
        apiKey: String? = nil,
        model: String = "local",
        userText: String = Self.defaultUserText,
        timeoutSeconds: Int = Self.defaultTimeoutSeconds,
        maxTokens: Int = Self.defaultMaxTokens
    ) {
        self.baseURL = baseURL
        self.apiKey = apiKey
        self.model = model
        self.userText = userText
        self.timeoutSeconds = max(1, timeoutSeconds)
        self.maxTokens = max(1, maxTokens)
    }

    public var chatCompletionsURL: String {
        baseURL.trimmingCharacters(in: CharacterSet(charactersIn: "/")) + "/chat/completions"
    }

    public var curlCommand: String {
        let payloadString = (try? JSONEncoder.clientSmoke.encode(payload))
            .flatMap { String(data: $0, encoding: .utf8) }
            ?? #"{"messages":[{"content":"\#(Self.defaultUserText)","role":"user"}],"model":"local","stream":false}"#

        var lines = [
            "curl -fsS --max-time \(timeoutSeconds) \(ShellQuoter.quote(chatCompletionsURL)) \\"
        ]

        if let apiKey, !apiKey.isEmpty {
            lines.append("  -H \(ShellQuoter.quote("Authorization: Bearer \(apiKey)")) \\")
        }

        lines.append("  -H \(ShellQuoter.quote("Content-Type: application/json")) \\")
        lines.append("  -d \(ShellQuoter.quote(payloadString))")

        return lines.joined(separator: "\n")
    }

    public var payloadData: Data {
        (try? JSONEncoder.clientSmoke.encode(payload)) ?? Data()
    }

    private var payload: Payload {
        Payload(
            maxTokens: maxTokens,
            model: model,
            stream: false,
            messages: [
                Message(role: "user", content: userText)
            ]
        )
    }

    private struct Payload: Encodable {
        var maxTokens: Int
        var model: String
        var stream: Bool
        var messages: [Message]

        enum CodingKeys: String, CodingKey {
            case maxTokens = "max_tokens"
            case messages
            case model
            case stream
        }
    }

    private struct Message: Encodable {
        var role: String
        var content: String
    }
}

private extension JSONEncoder {
    static var clientSmoke: JSONEncoder {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        return encoder
    }
}
