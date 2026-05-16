import Foundation

public struct ClientSmokeRequest: Equatable, Sendable {
    public var baseURL: String
    public var apiKey: String
    public var model: String
    public var userText: String

    public init(
        baseURL: String,
        apiKey: String = "local",
        model: String = "local",
        userText: String = "Hazakura AI Mobile runtime smoke. Reply with OK."
    ) {
        self.baseURL = baseURL
        self.apiKey = apiKey
        self.model = model
        self.userText = userText
    }

    public var chatCompletionsURL: String {
        baseURL.trimmingCharacters(in: CharacterSet(charactersIn: "/")) + "/chat/completions"
    }

    public var curlCommand: String {
        let payload = Payload(
            model: model,
            stream: false,
            messages: [
                Message(role: "user", content: userText)
            ]
        )

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        let payloadString = (try? encoder.encode(payload))
            .flatMap { String(data: $0, encoding: .utf8) }
            ?? #"{"messages":[{"content":"Hazakura AI Mobile runtime smoke. Reply with OK.","role":"user"}],"model":"local","stream":false}"#

        return """
        curl -sS \(ShellQuoter.quote(chatCompletionsURL)) \\
          -H \(ShellQuoter.quote("Authorization: Bearer \(apiKey)")) \\
          -H \(ShellQuoter.quote("Content-Type: application/json")) \\
          -d \(ShellQuoter.quote(payloadString))
        """
    }

    private struct Payload: Encodable {
        var model: String
        var stream: Bool
        var messages: [Message]
    }

    private struct Message: Encodable {
        var role: String
        var content: String
    }
}
