import Foundation
import XCTest
@testable import HazakuraLLMManagerCore

final class RuntimeUpdateAvailabilityCheckerTests: XCTestCase {
    override func tearDown() {
        RuntimeUpdateURLProtocol.result = nil
        RuntimeUpdateURLProtocol.observedRequest = nil
        super.tearDown()
    }

    func testBuildNumberParsesLlamaCppReleaseStyleTags() {
        XCTAssertEqual(RuntimeUpdateAvailabilityChecker.buildNumber(in: "b9060"), 9060)
        XCTAssertEqual(RuntimeUpdateAvailabilityChecker.buildNumber(in: "llama-server version b4600"), 4600)
        XCTAssertNil(RuntimeUpdateAvailabilityChecker.buildNumber(in: "llama-server custom build"))
    }

    func testCheckReportsUpdateAvailableWhenLocalBuildIsOlder() async throws {
        RuntimeUpdateURLProtocol.result = .success(
            statusCode: 200,
            body: """
            {
              "tag_name": "b9060",
              "html_url": "https://github.com/ggml-org/llama.cpp/releases/tag/b9060",
              "published_at": "2026-05-07T18:36:22Z"
            }
            """
        )

        let checker = RuntimeUpdateAvailabilityChecker(session: makeSession())
        let result = try await checker.check(
            target: .llamaCpp,
            localVersionSummary: "llama-server version b4600"
        )

        XCTAssertEqual(result.latestRelease.tagName, "b9060")
        XCTAssertEqual(result.comparison, .updateAvailable)
        XCTAssertEqual(result.title, "Update available: b9060")
        XCTAssertEqual(RuntimeUpdateURLProtocol.observedRequest?.value(forHTTPHeaderField: "Accept"), "application/vnd.github+json")
    }

    func testCheckReportsCurrentWhenLocalBuildMatchesLatestRelease() async throws {
        RuntimeUpdateURLProtocol.result = .success(
            statusCode: 200,
            body: #"{"tag_name":"b9060","html_url":"https://github.com/ggml-org/llama.cpp/releases/tag/b9060","published_at":"2026-05-07T18:36:22Z"}"#
        )

        let checker = RuntimeUpdateAvailabilityChecker(session: makeSession())
        let result = try await checker.check(
            target: .llamaCpp,
            localVersionSummary: "llama-server version b9060"
        )

        XCTAssertEqual(result.comparison, .currentOrNewer)
        XCTAssertTrue(result.detail.contains("at least as new"))
    }

    func testCheckKeepsLatestReleaseWhenLocalVersionCannotBeCompared() async throws {
        RuntimeUpdateURLProtocol.result = .success(
            statusCode: 200,
            body: #"{"tag_name":"b9060","html_url":"https://github.com/ggml-org/llama.cpp/releases/tag/b9060","published_at":"2026-05-07T18:36:22Z"}"#
        )

        let checker = RuntimeUpdateAvailabilityChecker(session: makeSession())
        let result = try await checker.check(
            target: .llamaCpp,
            localVersionSummary: nil
        )

        XCTAssertEqual(result.comparison, .unknownLocalVersion)
        XCTAssertTrue(result.detail.contains("Run Check Runtime first"))
    }

    func testCheckThrowsForHTTPFailure() async {
        RuntimeUpdateURLProtocol.result = .success(statusCode: 503, body: "{}")

        let checker = RuntimeUpdateAvailabilityChecker(session: makeSession())

        do {
            _ = try await checker.check(target: .llamaCpp, localVersionSummary: "b1")
            XCTFail("Expected HTTP status failure.")
        } catch let error as RuntimeUpdateAvailabilityError {
            XCTAssertEqual(error, .httpStatus(503))
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    private func makeSession() -> URLSession {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [RuntimeUpdateURLProtocol.self]
        return URLSession(configuration: configuration)
    }
}

private final class RuntimeUpdateURLProtocol: URLProtocol {
    enum Result {
        case success(statusCode: Int, body: String)
        case failure(Error)
    }

    static var result: Result?
    static var observedRequest: URLRequest?

    override class func canInit(with request: URLRequest) -> Bool {
        true
    }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        request
    }

    override func startLoading() {
        Self.observedRequest = request

        switch Self.result {
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
        case nil:
            client?.urlProtocol(self, didFailWithError: URLError(.badServerResponse))
        }
    }

    override func stopLoading() {}
}
