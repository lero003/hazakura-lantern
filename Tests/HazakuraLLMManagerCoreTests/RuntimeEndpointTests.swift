import XCTest
@testable import HazakuraLLMManagerCore

final class RuntimeEndpointTests: XCTestCase {
    func testEnvironmentSnippetKeepsDefaultLocalValuesReadable() throws {
        let endpoint = RuntimeEndpoint(
            apiBaseURL: try XCTUnwrap(URL(string: "http://localhost:1234/v1")),
            healthCheckURL: nil
        )

        XCTAssertEqual(
            endpoint.environmentSnippet,
            """
            OPENAI_BASE_URL=http://localhost:1234/v1
            OPENAI_API_KEY=local
            """
        )
    }

    func testEnvironmentSnippetShellQuotesAdapterScopedValues() throws {
        let endpoint = RuntimeEndpoint(
            apiBaseURL: try XCTUnwrap(URL(string: "http://localhost:1234/v1?profile=owner-desk")),
            healthCheckURL: nil,
            apiKey: "owner's local key"
        )

        XCTAssertEqual(
            endpoint.environmentSnippet,
            """
            OPENAI_BASE_URL='http://localhost:1234/v1?profile=owner-desk'
            OPENAI_API_KEY='owner'\\''s local key'
            """
        )
    }

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
