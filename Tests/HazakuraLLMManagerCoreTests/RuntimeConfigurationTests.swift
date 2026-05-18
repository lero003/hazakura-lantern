import XCTest
@testable import HazakuraLLMManagerCore

final class RuntimeConfigurationTests: XCTestCase {
    func testAPIBaseURLUsesConfiguredPort() {
        var config = RuntimeConfiguration.defaultValue
        config.port = 9876

        XCTAssertEqual(config.apiBaseURL, "http://localhost:9876/v1")
    }

    func testClientHostKeepsLocalDefaultsCopyable() {
        var config = RuntimeConfiguration.defaultValue

        config.host = "127.0.0.1"
        XCTAssertEqual(config.apiBaseURL, "http://localhost:1234/v1")

        config.host = "0.0.0.0"
        XCTAssertEqual(config.apiBaseURL, "http://localhost:1234/v1")

        config.host = "::1"
        XCTAssertEqual(config.apiBaseURL, "http://localhost:1234/v1")
    }

    func testAPIBaseURLUsesConfiguredReachableHost() {
        var config = RuntimeConfiguration.defaultValue
        config.host = "192.168.1.12"
        config.port = 9876

        XCTAssertEqual(config.apiBaseURL, "http://192.168.1.12:9876/v1")
    }

    func testAPIBaseURLBracketsIPv6Hosts() {
        var config = RuntimeConfiguration.defaultValue
        config.host = "fd00::12"
        config.port = 9876

        XCTAssertEqual(config.apiBaseURL, "http://[fd00::12]:9876/v1")
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
        XCTAssertEqual(config.endpointHealthCurlCommand, "curl -fsS --max-time 5 http://localhost:9876/v1/models")
    }
}
