import XCTest
@testable import HazakuraLLMManagerCore

final class EndpointHealthCheckerTests: XCTestCase {
    override func tearDown() {
        EndpointHealthURLProtocol.result = nil
        super.tearDown()
    }

    func testCheckReturnsHealthyForSuccessfulHTTPStatus() async throws {
        EndpointHealthURLProtocol.result = .success(statusCode: 200)
        let checker = EndpointHealthChecker(session: makeSession())

        let status = await checker.check(try XCTUnwrap(URL(string: "http://localhost:1234/v1/models")))

        XCTAssertEqual(status, .healthy(statusCode: 200))
    }

    func testCheckReturnsUnhealthyForFailedHTTPStatus() async throws {
        EndpointHealthURLProtocol.result = .success(statusCode: 503)
        let checker = EndpointHealthChecker(session: makeSession())

        let status = await checker.check(try XCTUnwrap(URL(string: "http://localhost:1234/v1/models")))

        XCTAssertEqual(status, .unhealthy(message: "Health check returned HTTP 503."))
    }

    func testCheckReturnsUnhealthyForRequestFailure() async throws {
        EndpointHealthURLProtocol.result = .failure(URLError(.cannotConnectToHost))
        let checker = EndpointHealthChecker(session: makeSession())

        let status = await checker.check(try XCTUnwrap(URL(string: "http://localhost:1234/v1/models")))

        guard case .unhealthy(let message) = status else {
            return XCTFail("Expected unhealthy status.")
        }

        XCTAssertTrue(message.hasPrefix("Health check failed:"))
    }

    private func makeSession() -> URLSession {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [EndpointHealthURLProtocol.self]
        return URLSession(configuration: configuration)
    }
}

private final class EndpointHealthURLProtocol: URLProtocol {
    enum Result {
        case success(statusCode: Int)
        case failure(Error)
    }

    static var result: Result?

    override class func canInit(with request: URLRequest) -> Bool {
        true
    }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        request
    }

    override func startLoading() {
        guard let result = Self.result else {
            client?.urlProtocol(self, didFailWithError: URLError(.badServerResponse))
            return
        }

        switch result {
        case .success(let statusCode):
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: statusCode,
                httpVersion: nil,
                headerFields: nil
            )!
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: Data())
            client?.urlProtocolDidFinishLoading(self)
        case .failure(let error):
            client?.urlProtocol(self, didFailWithError: error)
        }
    }

    override func stopLoading() {}
}
