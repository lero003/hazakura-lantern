import Foundation

public struct ClientSmokeResult: Equatable, Sendable {
    public enum RequestMode: String, Equatable, Sendable {
        case nonStreaming = "non-streaming"
    }

    public var responseText: String
    public var elapsedSeconds: Double
    public var outputCharacterCount: Int
    public var requestMode: RequestMode
    public var timeoutSeconds: Int

    public init(
        responseText: String,
        elapsedSeconds: Double = 0,
        requestMode: RequestMode = .nonStreaming,
        timeoutSeconds: Int = 60
    ) {
        self.responseText = responseText
        self.elapsedSeconds = max(0, elapsedSeconds)
        self.outputCharacterCount = responseText.count
        self.requestMode = requestMode
        self.timeoutSeconds = max(1, timeoutSeconds)
    }
}

public enum ClientSmokeError: Error, Equatable, Sendable {
    case invalidEndpoint(String)
    case connectionFailed(String)
    case timedOut(seconds: Int, url: String)
    case httpStatus(Int, bodySnippet: String?)
    case malformedResponse(String)
    case requestFailed(String)

    public var message: String {
        switch self {
        case .invalidEndpoint(let endpoint):
            return "Smoke request endpoint is invalid: \(endpoint)."
        case .connectionFailed(let url):
            return "No server responded at \(url). Start the runtime or verify the configured port."
        case .timedOut(let seconds, let url):
            return "Smoke request timed out after \(seconds) seconds for \(url)."
        case .httpStatus(let statusCode, let bodySnippet):
            if let bodySnippet, !bodySnippet.isEmpty {
                return "Smoke request returned HTTP \(statusCode): \(bodySnippet)"
            }
            return "Smoke request returned HTTP \(statusCode)."
        case .malformedResponse(let detail):
            return "Smoke response could not be read: \(detail)"
        case .requestFailed(let detail):
            return "Smoke request failed: \(detail)"
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
                throw ClientSmokeError.malformedResponse("The server did not return an HTTP response.")
            }

            guard (200...299).contains(httpResponse.statusCode) else {
                throw ClientSmokeError.httpStatus(
                    httpResponse.statusCode,
                    bodySnippet: Self.bodySnippet(from: data)
                )
            }

            let responseText = try Self.decodeResponseText(from: data)
            return ClientSmokeResult(
                responseText: responseText,
                elapsedSeconds: Date().timeIntervalSince(startedAt),
                requestMode: .nonStreaming,
                timeoutSeconds: request.timeoutSeconds
            )
        } catch let smokeError as ClientSmokeError {
            throw smokeError
        } catch {
            throw Self.mappedRequestError(error, url: urlString, timeoutSeconds: request.timeoutSeconds)
        }
    }

    private static func decodeResponseText(from data: Data) throws -> String {
        do {
            let response = try JSONDecoder().decode(ChatCompletionsResponse.self, from: data)
            guard let content = response.choices.first?.message.content else {
                throw ClientSmokeError.malformedResponse("No message content was found in the first choice.")
            }
            return content
        } catch let smokeError as ClientSmokeError {
            throw smokeError
        } catch {
            throw ClientSmokeError.malformedResponse(error.localizedDescription)
        }
    }

    private static func mappedRequestError(
        _ error: Error,
        url: String,
        timeoutSeconds: Int
    ) -> ClientSmokeError {
        guard let urlError = error as? URLError else {
            return .requestFailed(error.localizedDescription)
        }

        switch urlError.code {
        case .cannotConnectToHost, .cannotFindHost, .networkConnectionLost:
            return .connectionFailed(url)
        case .timedOut:
            return .timedOut(seconds: timeoutSeconds, url: url)
        default:
            return .requestFailed(urlError.localizedDescription)
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

        let limit = 240
        if body.count <= limit {
            return body
        }

        return String(body.prefix(limit)) + "..."
    }
}

private struct ChatCompletionsResponse: Decodable {
    var choices: [Choice]

    struct Choice: Decodable {
        var message: Message
    }

    struct Message: Decodable {
        var content: String?
    }
}
