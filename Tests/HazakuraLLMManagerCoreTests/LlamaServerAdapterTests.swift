import XCTest
@testable import HazakuraLLMManagerCore

final class LlamaServerAdapterTests: XCTestCase {
    func testBuildCommandUsesRequiredLlamaServerArguments() throws {
        let config = RuntimeConfiguration(
            runtimeExecutablePath: "/opt/llama.cpp/llama-server",
            modelPath: "/Users/kei/Models/qwen.gguf",
            host: "127.0.0.1",
            port: 1234,
            contextSize: 32768,
            threads: "auto",
            gpuLayers: "auto",
            additionalArguments: ""
        )

        let command = try LlamaServerAdapter().buildLaunchCommand(config: config)

        XCTAssertEqual(command.executablePath, "/opt/llama.cpp/llama-server")
        XCTAssertEqual(command.arguments, [
            "-m", "/Users/kei/Models/qwen.gguf",
            "--host", "127.0.0.1",
            "--port", "1234",
            "-c", "32768"
        ])
    }

    func testBuildCommandAddsExplicitNumericOptionsAndAdditionalArguments() throws {
        let config = RuntimeConfiguration(
            runtimeExecutablePath: "/usr/local/bin/llama-server",
            modelPath: "/Users/kei/Models/qwen.gguf",
            host: "127.0.0.1",
            port: 8080,
            contextSize: 8192,
            threads: "8",
            gpuLayers: "35",
            additionalArguments: "--alias \"qwen local\""
        )

        let command = try LlamaServerAdapter().buildLaunchCommand(config: config)

        XCTAssertEqual(command.arguments, [
            "-m", "/Users/kei/Models/qwen.gguf",
            "--host", "127.0.0.1",
            "--port", "8080",
            "-c", "8192",
            "-t", "8",
            "-ngl", "35",
            "--alias", "qwen local"
        ])
    }

    func testEndpointURLsUseConfiguredPort() {
        var config = RuntimeConfiguration.defaultValue
        config.port = 9876

        let adapter = LlamaServerAdapter()

        XCTAssertEqual(adapter.apiBaseURL(config: config), URL(string: "http://localhost:9876/v1"))
        XCTAssertEqual(adapter.healthCheckURL(config: config), URL(string: "http://localhost:9876/v1/models"))
    }

    func testRejectsInvalidPort() {
        var config = RuntimeConfiguration.defaultValue
        config.runtimeExecutablePath = "/usr/local/bin/llama-server"
        config.modelPath = "/Users/kei/Models/qwen.gguf"
        config.port = 0

        XCTAssertThrowsError(try LlamaServerAdapter().buildLaunchCommand(config: config)) { error in
            XCTAssertEqual(error as? RuntimeAdapterError, .invalidPort(0))
        }
    }

    func testRejectsInvalidThreadCount() {
        var config = RuntimeConfiguration.defaultValue
        config.runtimeExecutablePath = "/usr/local/bin/llama-server"
        config.modelPath = "/Users/kei/Models/qwen.gguf"
        config.threads = "0"

        XCTAssertThrowsError(try LlamaServerAdapter().buildLaunchCommand(config: config)) { error in
            XCTAssertEqual(error as? RuntimeAdapterError, .invalidNumericOption(name: "threads", value: "0"))
        }
    }

    func testRejectsInvalidGPULayers() {
        var config = RuntimeConfiguration.defaultValue
        config.runtimeExecutablePath = "/usr/local/bin/llama-server"
        config.modelPath = "/Users/kei/Models/qwen.gguf"
        config.gpuLayers = "many"

        XCTAssertThrowsError(try LlamaServerAdapter().buildLaunchCommand(config: config)) { error in
            XCTAssertEqual(error as? RuntimeAdapterError, .invalidNumericOption(name: "GPU layers", value: "many"))
        }
    }
}
