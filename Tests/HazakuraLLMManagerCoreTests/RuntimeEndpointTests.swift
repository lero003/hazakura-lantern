import XCTest
@testable import HazakuraLLMManagerCore

final class RuntimeEndpointTests: XCTestCase {
    func testEndpointHealthRequestUsesAdapterScopedTimeout() throws {
        let endpoint = RuntimeEndpoint(
            apiBaseURL: try XCTUnwrap(URL(string: "http://localhost:1234/v1")),
            healthCheckURL: try XCTUnwrap(URL(string: "http://localhost:1234/v1/models")),
            healthCheckTimeoutSeconds: 2
        )

        XCTAssertEqual(
            endpoint.endpointHealthCurlCommand,
            "curl -fsS --max-time 2 http://localhost:1234/v1/models"
        )
    }

    func testEndpointHealthRequestKeepsDefaultTimeout() throws {
        let endpoint = RuntimeEndpoint(
            apiBaseURL: try XCTUnwrap(URL(string: "http://localhost:1234/v1")),
            healthCheckURL: try XCTUnwrap(URL(string: "http://localhost:1234/v1/models"))
        )

        XCTAssertEqual(
            endpoint.endpointHealthCurlCommand,
            "curl -fsS --max-time 5 http://localhost:1234/v1/models"
        )
    }
}
