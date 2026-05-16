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
}
