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

        let result = try await client.run(request)

        XCTAssertEqual(result, ClientSmokeResult(responseText: "OK from local runtime"))
        let observedRequest = try XCTUnwrap(ClientSmokeURLProtocol.observedRequest)
        XCTAssertEqual(observedRequest.url?.absoluteString, "http://localhost:1234/v1/chat/completions")
        XCTAssertEqual(observedRequest.httpMethod, "POST")
        XCTAssertEqual(observedRequest.timeoutInterval, 9)
        XCTAssertEqual(observedRequest.value(forHTTPHeaderField: "Content-Type"), "application/json")
        XCTAssertEqual(observedRequest.value(forHTTPHeaderField: "Authorization"), "Bearer local key")

        let body = String(data: try XCTUnwrap(ClientSmokeURLProtocol.observedBody), encoding: .utf8)
        XCTAssertEqual(
            body,
            #"{"messages":[{"content":"Reply OK.","role":"user"}],"model":"qwen-local","stream":false}"#
        )
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
