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

    func testRejectsInvalidPort() {
        var config = RuntimeConfiguration.defaultValue
        config.runtimeExecutablePath = "/usr/local/bin/llama-server"
        config.modelPath = "/Users/kei/Models/qwen.gguf"
        config.port = 0

        XCTAssertThrowsError(try LlamaServerAdapter().buildLaunchCommand(config: config)) { error in
            XCTAssertEqual(error as? RuntimeAdapterError, .invalidPort(0))
        }
    }
}
