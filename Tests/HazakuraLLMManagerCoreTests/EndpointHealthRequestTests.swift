import XCTest
@testable import HazakuraLLMManagerCore

final class EndpointHealthRequestTests: XCTestCase {
    func testCurlCommandUsesFailFastHealthEndpoint() {
        let request = EndpointHealthRequest(healthURL: "http://localhost:9876/v1/models")

        XCTAssertEqual(request.curlCommand, "curl -fsS --max-time 5 http://localhost:9876/v1/models")
    }

    func testCurlCommandShellQuotesUnsafeHealthURL() {
        let request = EndpointHealthRequest(healthURL: "http://localhost:9876/v1/models?label=owner's runtime")

        XCTAssertEqual(
            request.curlCommand,
            "curl -fsS --max-time 5 'http://localhost:9876/v1/models?label=owner'\\''s runtime'"
        )
    }

    func testCurlCommandAllowsAdapterScopedTimeout() {
        let request = EndpointHealthRequest(
            healthURL: "http://localhost:9876/v1/models",
            timeoutSeconds: 2
        )

        XCTAssertEqual(request.curlCommand, "curl -fsS --max-time 2 http://localhost:9876/v1/models")
    }

    func testCurlCommandKeepsTimeoutPositive() {
        let request = EndpointHealthRequest(
            healthURL: "http://localhost:9876/v1/models",
            timeoutSeconds: 0
        )

        XCTAssertEqual(request.curlCommand, "curl -fsS --max-time 1 http://localhost:9876/v1/models")
    }
}
