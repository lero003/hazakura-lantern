import XCTest
@testable import HazakuraLLMManagerCore

final class RuntimeConfigurationTests: XCTestCase {
    func testAPIBaseURLUsesConfiguredPort() {
        var config = RuntimeConfiguration.defaultValue
        config.port = 9876

        XCTAssertEqual(config.apiBaseURL, "http://localhost:9876/v1")
    }

    func testEnvironmentSnippetUsesGeneratedBaseURLAndLocalAPIKey() {
        var config = RuntimeConfiguration.defaultValue
        config.port = 9876

        XCTAssertEqual(
            config.environmentSnippet,
            """
            OPENAI_BASE_URL=http://localhost:9876/v1
            OPENAI_API_KEY=local
            """
        )
    }

    func testAIMobileSmokeCurlCommandUsesConfiguredPort() {
        var config = RuntimeConfiguration.defaultValue
        config.port = 9876

        XCTAssertTrue(config.aiMobileSmokeCurlCommand.contains("http://localhost:9876/v1/chat/completions"))
        XCTAssertTrue(config.aiMobileSmokeCurlCommand.contains(#""stream":false"#))
    }

    func testEndpointHealthCurlCommandUsesConfiguredPort() {
        var config = RuntimeConfiguration.defaultValue
        config.port = 9876

        XCTAssertEqual(config.healthCheckURL, "http://localhost:9876/v1/models")
        XCTAssertEqual(config.endpointHealthCurlCommand, "curl -fsS http://localhost:9876/v1/models")
    }
}
