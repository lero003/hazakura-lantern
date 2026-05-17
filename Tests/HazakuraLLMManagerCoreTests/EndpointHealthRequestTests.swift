import XCTest
@testable import HazakuraLLMManagerCore

final class EndpointHealthRequestTests: XCTestCase {
    func testCurlCommandUsesFailFastHealthEndpoint() {
        let request = EndpointHealthRequest(healthURL: "http://localhost:9876/v1/models")

        XCTAssertEqual(request.curlCommand, "curl -fsS http://localhost:9876/v1/models")
    }

    func testCurlCommandShellQuotesUnsafeHealthURL() {
        let request = EndpointHealthRequest(healthURL: "http://localhost:9876/v1/models?label=owner's runtime")

        XCTAssertEqual(
            request.curlCommand,
            "curl -fsS 'http://localhost:9876/v1/models?label=owner'\\''s runtime'"
        )
    }
}
