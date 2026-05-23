import XCTest
@testable import HazakuraLLMManagerCore

final class ClientSmokeClientTests: XCTestCase {
    override func tearDown() {
        ClientSmokeURLProtocol.result = nil
        ClientSmokeURLProtocol.observedRequest = nil
        ClientSmokeURLProtocol.observedBody = nil
        super.tearDown()
    }

    func testRunPostsNonStreamingChatCompletionRequest() async throws {
        ClientSmokeURLProtocol.result = .success(
            statusCode: 200,
            body: #"{"choices":[{"message":{"content":"OK from local runtime"}}]}"#
        )
        let client = ClientSmokeClient(session: makeSession())
        let request = ClientSmokeRequest(
            baseURL: "http://localhost:1234/v1",
            apiKey: "local key",
            model: "qwen-local",
            userText: "Reply OK.",
            timeoutSeconds: 9
        )
        let beforeRun = Date()

        let result = try await client.run(request)

        XCTAssertEqual(result.responseText, "OK from local runtime")
        let startedAt = try XCTUnwrap(result.startedAt)
        XCTAssertGreaterThanOrEqual(startedAt.timeIntervalSince1970, beforeRun.timeIntervalSince1970)
        XCTAssertLessThanOrEqual(startedAt.timeIntervalSince1970, Date().timeIntervalSince1970)
        XCTAssertGreaterThanOrEqual(result.elapsedSeconds, 0)
        XCTAssertEqual(result.outputCharacterCount, 21)
        XCTAssertEqual(result.requestMode, .nonStreaming)
        XCTAssertEqual(result.timeoutSeconds, 9)
        XCTAssertNil(result.runtimeUsage)
        XCTAssertEqual(result.approximateOutputTokenCount, 6)
        XCTAssertNotNil(result.approximateOutputTokensPerSecond)
        let observedRequest = try XCTUnwrap(ClientSmokeURLProtocol.observedRequest)
        XCTAssertEqual(observedRequest.url?.absoluteString, "http://localhost:1234/v1/chat/completions")
        XCTAssertEqual(observedRequest.httpMethod, "POST")
        XCTAssertEqual(observedRequest.timeoutInterval, 9)
        XCTAssertEqual(observedRequest.value(forHTTPHeaderField: "Content-Type"), "application/json")
        XCTAssertEqual(observedRequest.value(forHTTPHeaderField: "Authorization"), "Bearer local key")

        let body = String(data: try XCTUnwrap(ClientSmokeURLProtocol.observedBody), encoding: .utf8)
        XCTAssertEqual(
            body,
            #"{"max_tokens":2048,"messages":[{"content":"Reply OK.","role":"user"}],"model":"qwen-local","stream":false}"#
        )
    }

    func testRunCapturesRuntimeReportedUsageWhenAvailable() async throws {
        ClientSmokeURLProtocol.result = .success(
            statusCode: 200,
            body: #"{"choices":[{"message":{"content":"OK"},"finish_reason":"stop"}],"usage":{"prompt_tokens":8,"completion_tokens":2,"total_tokens":10},"timings":{"predicted_per_second":12.5}}"#
        )
        let client = ClientSmokeClient(session: makeSession())
        let request = ClientSmokeRequest(baseURL: "http://localhost:1234/v1")

        let result = try await client.run(request)

        XCTAssertEqual(result.responseText, "OK")
        XCTAssertEqual(
            result.runtimeUsage,
            ClientSmokeResult.Usage(promptTokens: 8, completionTokens: 2, totalTokens: 10)
        )
        XCTAssertEqual(result.finishReason, "stop")
        XCTAssertEqual(result.outputTokensPerSecond, 12.5)
        XCTAssertTrue(result.usesRuntimeReportedOutputRate)
        XCTAssertFalse(result.usesApproximateOutputRate)
        XCTAssertNil(result.approximateOutputTokenCount)
        XCTAssertNil(result.approximateOutputTokensPerSecond)
    }

    func testRunFallsBackToElapsedUsageRateWhenRuntimeTimingIsMissing() async throws {
        ClientSmokeURLProtocol.result = .success(
            statusCode: 200,
            body: #"{"choices":[{"message":{"content":"OK"}}],"usage":{"completion_tokens":2}}"#
        )
        let client = ClientSmokeClient(session: makeSession())
        let request = ClientSmokeRequest(baseURL: "http://localhost:1234/v1")

        let result = try await client.run(request)

        XCTAssertEqual(result.runtimeUsage, ClientSmokeResult.Usage(completionTokens: 2))
        XCTAssertNotNil(result.outputTokensPerSecond)
        XCTAssertFalse(result.usesRuntimeReportedOutputRate)
        XCTAssertFalse(result.usesApproximateOutputRate)
    }

    func testRunCapturesLlamaServerTimingTokenUsageWhenStandardUsageIsMissing() async throws {
        ClientSmokeURLProtocol.result = .success(
            statusCode: 200,
            body: #"{"choices":[{"message":{"content":"OK"}}],"timings":{"cache_n":3,"prompt_n":5,"predicted_n":2,"predicted_per_second":12.5}}"#
        )
        let client = ClientSmokeClient(session: makeSession())
        let request = ClientSmokeRequest(baseURL: "http://localhost:1234/v1")

        let result = try await client.run(request)

        XCTAssertEqual(
            result.runtimeUsage,
            ClientSmokeResult.Usage(promptTokens: 8, completionTokens: 2, totalTokens: 10)
        )
        XCTAssertEqual(result.outputTokensPerSecond, 12.5)
        XCTAssertTrue(result.usesRuntimeReportedOutputRate)
        XCTAssertNil(result.approximateOutputTokenCount)
    }

    func testRunPrefersStandardUsageOverTimingTokenCounts() async throws {
        ClientSmokeURLProtocol.result = .success(
            statusCode: 200,
            body: #"{"choices":[{"message":{"content":"OK"}}],"usage":{"prompt_tokens":8,"completion_tokens":2,"total_tokens":10},"timings":{"cache_n":50,"prompt_n":40,"predicted_n":30,"predicted_per_second":12.5}}"#
        )
        let client = ClientSmokeClient(session: makeSession())
        let request = ClientSmokeRequest(baseURL: "http://localhost:1234/v1")

        let result = try await client.run(request)

        XCTAssertEqual(
            result.runtimeUsage,
            ClientSmokeResult.Usage(promptTokens: 8, completionTokens: 2, totalTokens: 10)
        )
        XCTAssertEqual(result.outputTokensPerSecond, 12.5)
    }

    func testRunUsesReasoningContentWhenMessageContentIsEmpty() async throws {
        ClientSmokeURLProtocol.result = .success(
            statusCode: 200,
            body: #"{"choices":[{"message":{"content":"","reasoning_content":"  Decoded reasoning text\n"}}],"usage":{"completion_tokens":4}}"#
        )
        let client = ClientSmokeClient(session: makeSession())
        let request = ClientSmokeRequest(baseURL: "http://localhost:1234/v1")

        let result = try await client.run(request)

        XCTAssertEqual(result.responseText, "Decoded reasoning text")
        XCTAssertEqual(result.runtimeUsage, ClientSmokeResult.Usage(completionTokens: 4))
        XCTAssertNotNil(result.outputTokensPerSecond)
    }

    func testRunUsesTextPartsWhenMessageContentIsArray() async throws {
        ClientSmokeURLProtocol.result = .success(
            statusCode: 200,
            body: #"{"choices":[{"message":{"content":[{"type":"text","text":" First line "},{"type":"image_url","text":"ignored"},{"text":"Second line"}]}}]}"#
        )
        let client = ClientSmokeClient(session: makeSession())
        let request = ClientSmokeRequest(baseURL: "http://localhost:1234/v1")

        let result = try await client.run(request)

        XCTAssertEqual(result.responseText, "First line\nSecond line")
        XCTAssertEqual(result.outputCharacterCount, 22)
        XCTAssertEqual(result.approximateOutputTokenCount, 6)
    }

    func testRunUsesChoiceTextFallbackWhenMessageIsMissing() async throws {
        ClientSmokeURLProtocol.result = .success(
            statusCode: 200,
            body: #"{"choices":[{"text":"  OK from legacy-compatible runtime\n","finish_reason":"stop"}]}"#
        )
        let client = ClientSmokeClient(session: makeSession())
        let request = ClientSmokeRequest(baseURL: "http://localhost:1234/v1")

        let result = try await client.run(request)

        XCTAssertEqual(result.responseText, "OK from legacy-compatible runtime")
        XCTAssertEqual(result.finishReason, "stop")
        XCTAssertEqual(result.outputCharacterCount, 33)
        XCTAssertEqual(result.approximateOutputTokenCount, 9)
    }

    func testApproximateTokenMetricsAreOnlyReportedWhenUsageIsMissing() {
        let startedAt = Date(timeIntervalSince1970: 1_779_501_600)
        let result = ClientSmokeResult(responseText: "abcdefgh", startedAt: startedAt, elapsedSeconds: 2)

        XCTAssertEqual(result.startedAt, startedAt)
        XCTAssertNil(result.runtimeUsage)
        XCTAssertEqual(result.approximateOutputTokenCount, 2)
        XCTAssertEqual(result.approximateOutputTokensPerSecond, 1)
        XCTAssertEqual(result.outputTokensPerSecond, 1)
        XCTAssertTrue(result.usesApproximateOutputRate)
    }

    func testClientSmokeResultOmitsBlankFinishReason() {
        let result = ClientSmokeResult(responseText: "OK", finishReason: "  ")

        XCTAssertNil(result.finishReason)
    }

    func testRunRejectsInvalidEndpointBeforeRequest() async {
        let client = ClientSmokeClient(session: makeSession())
        let request = ClientSmokeRequest(baseURL: "not a local endpoint")

        do {
            _ = try await client.run(request)
            XCTFail("Expected invalid endpoint error.")
        } catch let error as ClientSmokeError {
            XCTAssertEqual(error, .invalidEndpoint("not a local endpoint/chat/completions"))
        } catch {
            XCTFail("Unexpected error: \(error)")
        }

        XCTAssertNil(ClientSmokeURLProtocol.observedRequest)
    }

    func testRunMapsConnectionFailure() async {
        ClientSmokeURLProtocol.result = .failure(URLError(.cannotConnectToHost))
        let client = ClientSmokeClient(session: makeSession())
        let request = ClientSmokeRequest(baseURL: "http://localhost:1234/v1")

        await XCTAssertThrowsClientSmokeError(
            try await client.run(request),
            equals: .connectionFailed("http://localhost:1234/v1/chat/completions")
        )
    }

    func testRunMapsTimeout() async {
        ClientSmokeURLProtocol.result = .failure(URLError(.timedOut))
        let client = ClientSmokeClient(session: makeSession())
        let request = ClientSmokeRequest(baseURL: "http://localhost:1234/v1", timeoutSeconds: 3)

        await XCTAssertThrowsClientSmokeError(
            try await client.run(request),
            equals: .timedOut(seconds: 3, url: "http://localhost:1234/v1/chat/completions")
        )
    }

    func testRunMapsNonSuccessHTTPStatusWithBodySnippet() async {
        ClientSmokeURLProtocol.result = .success(statusCode: 503, body: "model still loading")
        let client = ClientSmokeClient(session: makeSession())
        let request = ClientSmokeRequest(baseURL: "http://localhost:1234/v1")

        await XCTAssertThrowsClientSmokeError(
            try await client.run(request),
            equals: .httpStatus(503, bodySnippet: "model still loading")
        )
    }

    func testRunMapsNonSuccessHTTPStatusWithNormalizedBoundedBodySnippet() async {
        ClientSmokeURLProtocol.result = .success(
            statusCode: 500,
            body: "first line\n\nsecond\tline " + String(repeating: "x", count: 260)
        )
        let client = ClientSmokeClient(session: makeSession())
        let request = ClientSmokeRequest(baseURL: "http://localhost:1234/v1")

        do {
            _ = try await client.run(request)
            XCTFail("Expected HTTP status error.")
        } catch let error as ClientSmokeError {
            guard case .httpStatus(500, let bodySnippet?) = error else {
                return XCTFail("Expected HTTP status with snippet, got \(error).")
            }
            XCTAssertTrue(bodySnippet.hasPrefix("first line second line "))
            XCTAssertTrue(bodySnippet.hasSuffix("..."))
            XCTAssertLessThanOrEqual(bodySnippet.count, 243)
            XCTAssertFalse(bodySnippet.contains("\n"))
            XCTAssertFalse(bodySnippet.contains("\t"))
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testRunMapsOpenAIStyleErrorMessageSnippet() async {
        ClientSmokeURLProtocol.result = .success(
            statusCode: 500,
            body: #"{"error":{"message":"model still loading\ntry again soon","type":"server_error"}}"#
        )
        let client = ClientSmokeClient(session: makeSession())
        let request = ClientSmokeRequest(baseURL: "http://localhost:1234/v1")

        await XCTAssertThrowsClientSmokeError(
            try await client.run(request),
            equals: .httpStatus(500, bodySnippet: "model still loading try again soon")
        )
    }

    func testRunMapsMalformedResponseJSON() async {
        ClientSmokeURLProtocol.result = .success(statusCode: 200, body: #"{"choices":[]}"#)
        let client = ClientSmokeClient(session: makeSession())
        let request = ClientSmokeRequest(baseURL: "http://localhost:1234/v1")

        do {
            _ = try await client.run(request)
            XCTFail("Expected malformed response error.")
        } catch let error as ClientSmokeError {
            guard case .malformedResponse(let message) = error else {
                return XCTFail("Expected malformed response, got \(error).")
            }
            XCTAssertEqual(message, "No message content was found in the first choice.")
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    private func makeSession() -> URLSession {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [ClientSmokeURLProtocol.self]
        return URLSession(configuration: configuration)
    }
}

private func XCTAssertThrowsClientSmokeError<T>(
    _ expression: @autoclosure () async throws -> T,
    equals expectedError: ClientSmokeError,
    file: StaticString = #filePath,
    line: UInt = #line
) async {
    do {
        _ = try await expression()
        XCTFail("Expected \(expectedError).", file: file, line: line)
    } catch let error as ClientSmokeError {
        XCTAssertEqual(error, expectedError, file: file, line: line)
    } catch {
        XCTFail("Unexpected error: \(error)", file: file, line: line)
    }
}

private final class ClientSmokeURLProtocol: URLProtocol {
    enum Result {
        case success(statusCode: Int, body: String)
        case failure(Error)
    }

    static var result: Result?
    static var observedRequest: URLRequest?
    static var observedBody: Data?

    override class func canInit(with request: URLRequest) -> Bool {
        true
    }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        request
    }

    override func startLoading() {
        Self.observedRequest = request
        Self.observedBody = request.httpBody ?? Self.data(from: request.httpBodyStream)

        guard let result = Self.result else {
            client?.urlProtocol(self, didFailWithError: URLError(.badServerResponse))
            return
        }

        switch result {
        case .success(let statusCode, let body):
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: statusCode,
                httpVersion: nil,
                headerFields: nil
            )!
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: Data(body.utf8))
            client?.urlProtocolDidFinishLoading(self)
        case .failure(let error):
            client?.urlProtocol(self, didFailWithError: error)
        }
    }

    override func stopLoading() {}

    private static func data(from stream: InputStream?) -> Data? {
        guard let stream else {
            return nil
        }

        stream.open()
        defer { stream.close() }

        var data = Data()
        let bufferSize = 1024
        let buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: bufferSize)
        defer { buffer.deallocate() }

        while stream.hasBytesAvailable {
            let count = stream.read(buffer, maxLength: bufferSize)
            if count > 0 {
                data.append(buffer, count: count)
            } else {
                break
            }
        }

        return data
    }
}
