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

        config.host = "[::]"
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

    func testLaunchSetupHintReportsMissingRuntimeAndModelSelections() {
        var config = RuntimeConfiguration.defaultValue
        config.runtimeExecutablePath = " \n"
        config.modelPath = "\t"

        XCTAssertEqual(
            config.launchSetupHint,
            "Choose a llama-server executable and .gguf model before starting."
        )
    }

    func testLaunchSetupHintReportsMissingRuntimeSelection() {
        var config = RuntimeConfiguration.defaultValue
        config.runtimeExecutablePath = ""
        config.modelPath = "/Users/kei/Models/qwen.gguf"

        XCTAssertEqual(config.launchSetupHint, "Choose a llama-server executable before starting.")
    }

    func testLaunchSetupHintReportsMissingModelSelection() {
        var config = RuntimeConfiguration.defaultValue
        config.runtimeExecutablePath = "/usr/local/bin/llama-server"
        config.modelPath = ""

        XCTAssertEqual(config.launchSetupHint, "Choose a .gguf model before starting.")
    }

    func testLaunchSetupHintReportsUnsupportedModelSelection() {
        var config = RuntimeConfiguration.defaultValue
        config.runtimeExecutablePath = "/usr/local/bin/llama-server"
        config.modelPath = "/Users/kei/Models/qwen.bin"

        XCTAssertEqual(
            config.launchSetupHint,
            "Choose a .gguf model file before starting. Lantern does not convert or download models."
        )
    }

    func testLaunchSetupHintReportsInvalidPortSelection() {
        var config = RuntimeConfiguration.defaultValue
        config.runtimeExecutablePath = "/usr/local/bin/llama-server"
        config.modelPath = "/Users/kei/Models/qwen.gguf"
        config.port = 70_000

        XCTAssertEqual(config.launchSetupHint, "Choose a port between 1 and 65535 before starting.")
    }

    func testLaunchSetupHintReportsInvalidContextSelection() {
        var config = RuntimeConfiguration.defaultValue
        config.runtimeExecutablePath = "/usr/local/bin/llama-server"
        config.modelPath = "/Users/kei/Models/qwen.gguf"
        config.contextSize = 0

        XCTAssertEqual(config.launchSetupHint, "Choose a context size greater than zero before starting.")
    }

    func testLaunchSetupHintReportsInvalidThreadsSelection() {
        var config = RuntimeConfiguration.defaultValue
        config.runtimeExecutablePath = "/usr/local/bin/llama-server"
        config.modelPath = "/Users/kei/Models/qwen.gguf"
        config.threads = "zero"

        XCTAssertEqual(config.launchSetupHint, "Set threads to auto or a positive integer before starting.")
    }

    func testLaunchSetupHintReportsInvalidGPULayersSelection() {
        var config = RuntimeConfiguration.defaultValue
        config.runtimeExecutablePath = "/usr/local/bin/llama-server"
        config.modelPath = "/Users/kei/Models/qwen.gguf"
        config.gpuLayers = "-1"

        XCTAssertEqual(config.launchSetupHint, "Set GPU layers to auto or a non-negative integer before starting.")
    }

    func testLaunchSetupHintReportsMalformedAdditionalArguments() {
        var config = RuntimeConfiguration.defaultValue
        config.runtimeExecutablePath = "/usr/local/bin/llama-server"
        config.modelPath = "/Users/kei/Models/qwen.gguf"
        config.additionalArguments = "--alias \"qwen"

        XCTAssertEqual(
            config.launchSetupHint,
            "Fix Additional Args before starting: Additional args contains an unterminated \" quote."
        )
    }

    func testLaunchSetupHintAcceptsAutoAndWhitespaceNumericSelections() {
        var config = RuntimeConfiguration.defaultValue
        config.runtimeExecutablePath = "/usr/local/bin/llama-server"
        config.modelPath = "/Users/kei/Models/qwen.gguf"
        config.threads = " auto "
        config.gpuLayers = " 0 "

        XCTAssertNil(config.launchSetupHint)
    }

    func testLaunchSetupHintAcceptsUppercaseGGUFModelSelection() {
        var config = RuntimeConfiguration.defaultValue
        config.runtimeExecutablePath = "/usr/local/bin/llama-server"
        config.modelPath = "/Users/kei/Models/qwen.GGUF"

        XCTAssertNil(config.launchSetupHint)
    }

    func testLaunchSetupHintIsNilWhenRequiredSelectionsArePresent() {
        var config = RuntimeConfiguration.defaultValue
        config.runtimeExecutablePath = "/usr/local/bin/llama-server"
        config.modelPath = "/Users/kei/Models/qwen.gguf"

        XCTAssertNil(config.launchSetupHint)
    }
}
