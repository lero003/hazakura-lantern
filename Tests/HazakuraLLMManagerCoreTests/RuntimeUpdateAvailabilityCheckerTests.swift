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
        XCTAssertEqual(RuntimeUpdateAvailabilityChecker.buildNumber(in: "version: 9240"), 9240)
        XCTAssertNil(RuntimeUpdateAvailabilityChecker.buildNumber(in: "llama-server custom build"))
    }

    func testLlamaCppTargetDefinesLatestReleaseURLWithoutForceUnwrap() throws {
        let url = try RuntimeUpdateCheckTarget.llamaCpp.latestReleaseURL()

        XCTAssertEqual(
            url.absoluteString,
            "https://api.github.com/repos/ggml-org/llama.cpp/releases/latest"
        )
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
        XCTAssertTrue(result.detail.contains("only reports release metadata"))
        XCTAssertTrue(result.detail.contains("outside Lantern"))
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
        XCTAssertTrue(result.detail.contains("does not prepare or run runtime updates"))
    }

    func testCheckReportsCurrentWhenLocalBuildIsNewerThanLatestRelease() async throws {
        RuntimeUpdateURLProtocol.result = .success(
            statusCode: 200,
            body: #"{"tag_name":"b9060","html_url":"https://github.com/ggml-org/llama.cpp/releases/tag/b9060","published_at":"2026-05-07T18:36:22Z"}"#
        )

        let checker = RuntimeUpdateAvailabilityChecker(session: makeSession())
        let result = try await checker.check(
            target: .llamaCpp,
            localVersionSummary: "llama-server version b9061"
        )

        XCTAssertEqual(result.comparison, .currentOrNewer)
        XCTAssertEqual(result.title, "Runtime appears current: b9060")
        XCTAssertTrue(result.detail.contains("at least as new"))
        XCTAssertTrue(result.detail.contains("does not prepare or run runtime updates"))
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
        XCTAssertTrue(result.detail.contains("does not prepare or run runtime updates"))
    }

    func testCheckReportsUnknownLatestVersionWhenReleaseTagCannotBeCompared() async throws {
        RuntimeUpdateURLProtocol.result = .success(
            statusCode: 200,
            body: #"{"tag_name":"server-release","html_url":"https://github.com/ggml-org/llama.cpp/releases/tag/server-release","published_at":"2026-05-07T18:36:22Z"}"#
        )

        let checker = RuntimeUpdateAvailabilityChecker(session: makeSession())
        let result = try await checker.check(
            target: .llamaCpp,
            localVersionSummary: "llama-server version b9060"
        )

        XCTAssertEqual(result.comparison, .unknownLatestVersion)
        XCTAssertEqual(result.title, "Latest llama.cpp release found")
        XCTAssertTrue(result.detail.contains("could not read a comparable release build number"))
        XCTAssertTrue(result.detail.contains("does not prepare or run runtime updates"))
    }

    func testCheckUsesExplicitLlamaCppLatestReleaseRequestMetadata() async throws {
        RuntimeUpdateURLProtocol.result = .success(
            statusCode: 200,
            body: #"{"tag_name":"b9060","html_url":"https://github.com/ggml-org/llama.cpp/releases/tag/b9060","published_at":"2026-05-07T18:36:22Z"}"#
        )

        let checker = RuntimeUpdateAvailabilityChecker(session: makeSession())
        _ = try await checker.check(target: .llamaCpp, localVersionSummary: nil)

        let request = try XCTUnwrap(RuntimeUpdateURLProtocol.observedRequest)
        XCTAssertEqual(request.url?.absoluteString, "https://api.github.com/repos/ggml-org/llama.cpp/releases/latest")
        XCTAssertEqual(request.value(forHTTPHeaderField: "Accept"), "application/vnd.github+json")
        XCTAssertEqual(request.value(forHTTPHeaderField: "User-Agent"), "Hazakura-Lantern")
        XCTAssertEqual(request.timeoutInterval, 8)
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
