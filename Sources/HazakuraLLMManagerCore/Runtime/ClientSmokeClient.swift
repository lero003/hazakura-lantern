import Foundation

public struct ClientSmokeResult: Equatable, Sendable {
    public enum RequestMode: String, Equatable, Sendable {
        case nonStreaming = "non-streaming"
    }

    public struct Usage: Equatable, Sendable {
        public var promptTokens: Int?
        public var completionTokens: Int?
        public var totalTokens: Int?

        public init(promptTokens: Int? = nil, completionTokens: Int? = nil, totalTokens: Int? = nil) {
            self.promptTokens = promptTokens
            self.completionTokens = completionTokens
            self.totalTokens = totalTokens
        }

        public var hasReportedTokens: Bool {
            promptTokens != nil || completionTokens != nil || totalTokens != nil
        }
    }

    public var responseText: String
    public var startedAt: Date?
    public var elapsedSeconds: Double
    public var outputCharacterCount: Int
    public var requestMode: RequestMode
    public var timeoutSeconds: Int
    public var runtimeUsage: Usage?
    public var approximateOutputTokenCount: Int?
    public var approximateOutputTokensPerSecond: Double?
    public var outputTokensPerSecond: Double?
    public var usesApproximateOutputRate: Bool
    public var usesRuntimeReportedOutputRate: Bool
    public var finishReason: String?
    public var requestURL: String?
    public var modelID: String?

    public init(
        responseText: String,
        startedAt: Date? = nil,
        elapsedSeconds: Double = 0,
        requestMode: RequestMode = .nonStreaming,
        timeoutSeconds: Int = 60,
        runtimeUsage: Usage? = nil,
        runtimeOutputTokensPerSecond: Double? = nil,
        finishReason: String? = nil,
        requestURL: String? = nil,
        modelID: String? = nil
    ) {
        self.responseText = responseText
        self.startedAt = startedAt
        self.elapsedSeconds = max(0, elapsedSeconds)
        self.outputCharacterCount = responseText.count
        self.requestMode = requestMode
        self.timeoutSeconds = max(1, timeoutSeconds)
        self.runtimeUsage = runtimeUsage?.hasReportedTokens == true ? runtimeUsage : nil
        self.finishReason = finishReason?.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty
        self.requestURL = requestURL?.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty
        self.modelID = modelID?.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty

        if self.runtimeUsage == nil {
            let approximateOutputTokenCount = Self.approximateOutputTokens(for: responseText)
            self.approximateOutputTokenCount = approximateOutputTokenCount
            if self.elapsedSeconds > 0, approximateOutputTokenCount > 0 {
                self.approximateOutputTokensPerSecond = Double(approximateOutputTokenCount) / self.elapsedSeconds
            } else {
                self.approximateOutputTokensPerSecond = nil
            }
        } else {
            self.approximateOutputTokenCount = nil
            self.approximateOutputTokensPerSecond = nil
        }

        if let runtimeOutputTokensPerSecond, runtimeOutputTokensPerSecond > 0 {
            self.outputTokensPerSecond = runtimeOutputTokensPerSecond
            self.usesApproximateOutputRate = false
            self.usesRuntimeReportedOutputRate = true
        } else if
            let completionTokens = self.runtimeUsage?.completionTokens,
            self.elapsedSeconds > 0,
            completionTokens > 0
        {
            self.outputTokensPerSecond = Double(completionTokens) / self.elapsedSeconds
            self.usesApproximateOutputRate = false
            self.usesRuntimeReportedOutputRate = false
        } else {
            self.outputTokensPerSecond = self.approximateOutputTokensPerSecond
            self.usesApproximateOutputRate = self.approximateOutputTokensPerSecond != nil
            self.usesRuntimeReportedOutputRate = false
        }
    }

    private static func approximateOutputTokens(for text: String) -> Int {
        guard !text.isEmpty else {
            return 0
        }

        return max(1, Int(ceil(Double(text.count) / 4.0)))
    }
}

public enum ClientSmokeError: Error, Equatable, Sendable {
    case invalidEndpoint(String)
    case connectionFailed(String)
    case timedOut(seconds: Int, url: String)
    case httpStatus(Int, url: String, bodySnippet: String?)
    case malformedResponse(String, url: String?)
    case requestFailed(String, url: String?)

    public var message: String {
        switch self {
        case .invalidEndpoint(let endpoint):
            return "Smoke request endpoint is invalid: \(endpoint)."
        case .connectionFailed(let url):
            return "No server responded at \(url). Start the runtime or verify the configured port."
        case .timedOut(let seconds, let url):
            return "Smoke request timed out after \(seconds) seconds for \(url)."
        case .httpStatus(let statusCode, let url, let bodySnippet):
            if let bodySnippet, !bodySnippet.isEmpty {
                return "Smoke request returned HTTP \(statusCode) for \(url): \(bodySnippet)"
            }
            return "Smoke request returned HTTP \(statusCode) for \(url)."
        case .malformedResponse(let detail, let url):
            if let url, !url.isEmpty {
                return "Smoke response from \(url) could not be read: \(detail)"
            }
            return "Smoke response could not be read: \(detail)"
        case .requestFailed(let detail, let url):
            if let url, !url.isEmpty {
                return "Smoke request failed for \(url): \(detail)"
            }
            return "Smoke request failed: \(detail)"
        }
    }

    public var requestURL: String? {
        switch self {
        case .invalidEndpoint(let endpoint):
            return endpoint
        case .connectionFailed(let url):
            return url
        case .timedOut(_, let url):
            return url
        case .httpStatus(_, let url, _):
            return url
        case .malformedResponse(_, let url):
            return url
        case .requestFailed(_, let url):
            return url
        }
    }
}

public protocol ClientSmokeRunning: Sendable {
    func run(_ request: ClientSmokeRequest) async throws -> ClientSmokeResult
}

public struct ClientSmokeClient: ClientSmokeRunning, Sendable {
    private let session: URLSession

    public init(session: URLSession = .shared) {
        self.session = session
    }

    public func run(_ request: ClientSmokeRequest) async throws -> ClientSmokeResult {
        let urlString = request.chatCompletionsURL

        guard
            let url = URL(string: urlString),
            let scheme = url.scheme?.lowercased(),
            ["http", "https"].contains(scheme),
            url.host != nil
        else {
            throw ClientSmokeError.invalidEndpoint(urlString)
        }

        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.timeoutInterval = TimeInterval(request.timeoutSeconds)
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if let apiKey = request.apiKey, !apiKey.isEmpty {
            urlRequest.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        }
        urlRequest.httpBody = request.payloadData

        let startedAt = Date()

        do {
            let (data, response) = try await session.data(for: urlRequest)

            guard let httpResponse = response as? HTTPURLResponse else {
                throw ClientSmokeError.malformedResponse("The server did not return an HTTP response.", url: urlString)
            }

            guard (200...299).contains(httpResponse.statusCode) else {
                throw ClientSmokeError.httpStatus(
                    httpResponse.statusCode,
                    url: urlString,
                    bodySnippet: Self.bodySnippet(from: data)
                )
            }

            let decodedResponse = try Self.decodeResponse(from: data, url: urlString)
            return ClientSmokeResult(
                responseText: decodedResponse.responseText,
                startedAt: startedAt,
                elapsedSeconds: Date().timeIntervalSince(startedAt),
                requestMode: .nonStreaming,
                timeoutSeconds: request.timeoutSeconds,
                runtimeUsage: decodedResponse.usage,
                runtimeOutputTokensPerSecond: decodedResponse.runtimeOutputTokensPerSecond,
                finishReason: decodedResponse.finishReason,
                requestURL: urlString,
                modelID: request.model
            )
        } catch let smokeError as ClientSmokeError {
            throw smokeError
        } catch {
            throw Self.mappedRequestError(error, url: urlString, timeoutSeconds: request.timeoutSeconds)
        }
    }

    private static func decodeResponse(from data: Data, url: String) throws -> DecodedClientSmokeResponse {
        do {
            let response = try JSONDecoder().decode(ChatCompletionsResponse.self, from: data)
            guard let choice = response.readableChoice, let content = choice.displayText else {
                throw ClientSmokeError.malformedResponse("No readable message content was found in any choice.", url: url)
            }
            return DecodedClientSmokeResponse(
                responseText: content,
                usage: response.usage?.clientSmokeUsage ?? response.timings?.clientSmokeUsage,
                runtimeOutputTokensPerSecond: response.timings?.runtimeOutputTokensPerSecond,
                finishReason: choice.finishReason
            )
        } catch let smokeError as ClientSmokeError {
            throw smokeError
        } catch {
            throw ClientSmokeError.malformedResponse(error.localizedDescription, url: url)
        }
    }

    private static func mappedRequestError(
        _ error: Error,
        url: String,
        timeoutSeconds: Int
    ) -> ClientSmokeError {
        guard let urlError = error as? URLError else {
            return .requestFailed(error.localizedDescription, url: url)
        }

        switch urlError.code {
        case .cannotConnectToHost, .cannotFindHost, .networkConnectionLost:
            return .connectionFailed(url)
        case .timedOut:
            return .timedOut(seconds: timeoutSeconds, url: url)
        default:
            return .requestFailed(urlError.localizedDescription, url: url)
        }
    }

    private static func bodySnippet(from data: Data) -> String? {
        guard
            let body = String(data: data, encoding: .utf8)?
                .trimmingCharacters(in: .whitespacesAndNewlines),
            !body.isEmpty
        else {
            return nil
        }

        let normalizedBody = normalizedSnippetText(Self.structuredErrorMessage(from: data) ?? body)

        let limit = 240
        if normalizedBody.count <= limit {
            return normalizedBody
        }

        return String(normalizedBody.prefix(limit)) + "..."
    }

    private static func normalizedSnippetText(_ text: String) -> String {
        text
            .split(whereSeparator: \.isWhitespace)
            .joined(separator: " ")
    }

    private static func structuredErrorMessage(from data: Data) -> String? {
        guard
            let response = try? JSONDecoder().decode(OpenAIErrorResponse.self, from: data),
            let message = response.message?.trimmingCharacters(in: .whitespacesAndNewlines),
            !message.isEmpty
        else {
            return nil
        }

        return message
    }
}

private struct DecodedClientSmokeResponse {
    var responseText: String
    var usage: ClientSmokeResult.Usage?
    var runtimeOutputTokensPerSecond: Double?
    var finishReason: String?
}

private struct OpenAIErrorResponse: Decodable {
    var error: ErrorPayload?
    var detail: ErrorPayload?
    var topLevelMessage: String?

    var message: String? {
        [error?.message, detail?.message, topLevelMessage]
            .compactMap { $0?.trimmingCharacters(in: .whitespacesAndNewlines) }
            .first { !$0.isEmpty }
    }

    enum CodingKeys: String, CodingKey {
        case error
        case detail
        case topLevelMessage = "message"
    }

    enum ErrorPayload: Decodable {
        case message(String?)
        case messages([String])

        var message: String? {
            switch self {
            case .message(let message):
                return message
            case .messages(let messages):
                let joinedMessages = messages
                    .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                    .filter { !$0.isEmpty }
                    .joined(separator: "; ")
                return joinedMessages.nilIfEmpty
            }
        }

        init(from decoder: Decoder) throws {
            let container = try decoder.singleValueContainer()

            if let message = try? container.decode(String.self) {
                self = .message(message)
                return
            }

            if let payloads = try? container.decode([ErrorPayload].self) {
                self = .messages(payloads.compactMap(\.message))
                return
            }

            let payload = try container.decode(MessagePayload.self)
            self = .message(payload.displayMessage)
        }

        private struct MessagePayload: Decodable {
            var message: String?
            var detail: String?
            var msg: String?
            var code: String?

            var displayMessage: String? {
                [message, detail, msg, code]
                    .compactMap { $0?.trimmingCharacters(in: .whitespacesAndNewlines) }
                    .first { !$0.isEmpty }
            }
        }
    }
}

private struct ChatCompletionsResponse: Decodable {
    var choices: [Choice]
    var usage: Usage?
    var timings: Timings?

    var readableChoice: Choice? {
        choices.first { $0.displayText != nil }
    }

    enum CodingKeys: String, CodingKey {
        case choices
        case usage
        case timings
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        choices = try container.decode([Choice].self, forKey: .choices)
        usage = try? container.decode(Usage.self, forKey: .usage)
        timings = try? container.decode(Timings.self, forKey: .timings)
    }

    struct Choice: Decodable {
        var message: Message?
        var text: String?
        var finishReason: String?

        enum CodingKeys: String, CodingKey {
            case message
            case text
            case finishReason = "finish_reason"
        }

        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            message = try? container.decode(Message.self, forKey: .message)
            text = try? container.decode(String.self, forKey: .text)
            finishReason = try? container.decode(String.self, forKey: .finishReason)
        }

        var displayText: String? {
            if let content = message?.displayText {
                return content
            }

            return text?.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty
        }
    }

    struct Message: Decodable {
        var content: MessageContent?
        var reasoningContent: String?

        enum CodingKeys: String, CodingKey {
            case content
            case reasoningContent = "reasoning_content"
        }

        var displayText: String? {
            if let content = content?.displayText, !content.isEmpty {
                return content
            }

            if
                let reasoningContent = reasoningContent?.trimmingCharacters(in: .whitespacesAndNewlines),
                !reasoningContent.isEmpty
            {
                return reasoningContent
            }

            return nil
        }
    }

    enum MessageContent: Decodable {
        case string(String)
        case parts([ContentPart])
        case part(ContentPart)

        var displayText: String {
            switch self {
            case .string(let content):
                return content.trimmingCharacters(in: .whitespacesAndNewlines)
            case .parts(let parts):
                return parts
                    .compactMap(\.displayText)
                    .joined(separator: "\n")
            case .part(let part):
                return part.displayText ?? ""
            }
        }

        init(from decoder: Decoder) throws {
            let container = try decoder.singleValueContainer()

            if let content = try? container.decode(String.self) {
                self = .string(content)
                return
            }

            if let parts = try? container.decode([ContentPart].self) {
                self = .parts(parts)
                return
            }

            if let contentPart = try? container.decode(ContentPart.self) {
                self = .part(contentPart)
                return
            }

            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Unsupported message content shape.")
        }
    }

    struct ContentPart: Decodable {
        var type: String?
        var text: String?

        init(from decoder: Decoder) throws {
            let container = try decoder.singleValueContainer()

            if let text = try? container.decode(String.self) {
                self.type = nil
                self.text = text
                return
            }

            guard let payload = try? container.decode(Payload.self) else {
                self.type = nil
                self.text = nil
                return
            }

            self.type = payload.type
            self.text = payload.text ?? payload.content
        }

        var displayText: String? {
            if
                let type = type?.trimmingCharacters(in: .whitespacesAndNewlines).lowercased(),
                !Self.textPartTypes.contains(type)
            {
                return nil
            }

            guard let text = text?.trimmingCharacters(in: .whitespacesAndNewlines), !text.isEmpty else {
                return nil
            }

            return text
        }

        private static let textPartTypes: Set<String> = ["text", "output_text"]

        private struct Payload: Decodable {
            var type: String?
            var text: String?
            var content: String?

            enum CodingKeys: String, CodingKey {
                case type
                case text
                case content
            }

            init(from decoder: Decoder) throws {
                let container = try decoder.container(keyedBy: CodingKeys.self)
                type = container.decodeLossyStringIfPresent(forKey: .type)
                text = container.decodeLossyStringIfPresent(forKey: .text)
                content = container.decodeLossyStringIfPresent(forKey: .content)
            }
        }
    }

    struct Usage: Decodable {
        var promptTokens: Int?
        var completionTokens: Int?
        var totalTokens: Int?

        enum CodingKeys: String, CodingKey {
            case promptTokens = "prompt_tokens"
            case completionTokens = "completion_tokens"
            case totalTokens = "total_tokens"
        }

        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            promptTokens = container.decodeLossyPositiveIntIfPresent(forKey: .promptTokens)
            completionTokens = container.decodeLossyPositiveIntIfPresent(forKey: .completionTokens)
            totalTokens = container.decodeLossyPositiveIntIfPresent(forKey: .totalTokens)
        }

        var clientSmokeUsage: ClientSmokeResult.Usage? {
            let usage = ClientSmokeResult.Usage(
                promptTokens: promptTokens,
                completionTokens: completionTokens,
                totalTokens: totalTokens
            )
            return usage.hasReportedTokens ? usage : nil
        }
    }

    struct Timings: Decodable {
        var cacheTokenCount: Int?
        var promptTokenCount: Int?
        var predictedTokenCount: Int?
        var predictedPerSecond: Double?

        enum CodingKeys: String, CodingKey {
            case cacheTokenCount = "cache_n"
            case promptTokenCount = "prompt_n"
            case predictedTokenCount = "predicted_n"
            case predictedPerSecond = "predicted_per_second"
        }

        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            cacheTokenCount = container.decodeLossyPositiveIntIfPresent(forKey: .cacheTokenCount)
            promptTokenCount = container.decodeLossyPositiveIntIfPresent(forKey: .promptTokenCount)
            predictedTokenCount = container.decodeLossyPositiveIntIfPresent(forKey: .predictedTokenCount)
            predictedPerSecond = container.decodeLossyPositiveDoubleIfPresent(forKey: .predictedPerSecond)
        }

        var clientSmokeUsage: ClientSmokeResult.Usage? {
            let promptTokens = sumPositiveTokenCounts(cacheTokenCount, promptTokenCount)
            let completionTokens = positiveTokenCount(predictedTokenCount)
            let totalTokens = sumPositiveTokenCounts(promptTokens, completionTokens)
            let usage = ClientSmokeResult.Usage(
                promptTokens: promptTokens,
                completionTokens: completionTokens,
                totalTokens: totalTokens
            )
            return usage.hasReportedTokens ? usage : nil
        }

        var runtimeOutputTokensPerSecond: Double? {
            guard let predictedPerSecond, predictedPerSecond > 0 else {
                return nil
            }

            return predictedPerSecond
        }

        private func positiveTokenCount(_ count: Int?) -> Int? {
            guard let count, count > 0 else {
                return nil
            }

            return count
        }

        private func sumPositiveTokenCounts(_ counts: Int?...) -> Int? {
            let total = counts
                .compactMap(positiveTokenCount)
                .reduce(0, +)

            return total > 0 ? total : nil
        }
    }
}

private extension String {
    var nilIfEmpty: String? {
        isEmpty ? nil : self
    }
}

private extension KeyedDecodingContainer {
    func decodeLossyStringIfPresent(forKey key: Key) -> String? {
        try? decode(String.self, forKey: key)
    }

    func decodeLossyPositiveIntIfPresent(forKey key: Key) -> Int? {
        if let value = try? decode(Int.self, forKey: key), value > 0 {
            return value
        }

        if let value = try? decode(Double.self, forKey: key) {
            return positiveInteger(from: value)
        }

        if
            let rawValue = try? decode(String.self, forKey: key),
            let value = Double(rawValue.trimmingCharacters(in: .whitespacesAndNewlines))
        {
            return positiveInteger(from: value)
        }

        return nil
    }

    func decodeLossyPositiveDoubleIfPresent(forKey key: Key) -> Double? {
        if let value = try? decode(Double.self, forKey: key), value.isFinite, value > 0 {
            return value
        }

        if
            let rawValue = try? decode(String.self, forKey: key),
            let value = Double(rawValue.trimmingCharacters(in: .whitespacesAndNewlines)),
            value.isFinite,
            value > 0
        {
            return value
        }

        return nil
    }

    private func positiveInteger(from value: Double) -> Int? {
        guard
            value.isFinite,
            value > 0,
            value.rounded(.towardZero) == value,
            value <= Double(Int.max)
        else {
            return nil
        }

        return Int(value)
    }
}
