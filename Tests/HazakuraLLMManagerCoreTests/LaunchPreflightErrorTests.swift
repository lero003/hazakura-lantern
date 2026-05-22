import XCTest
@testable import HazakuraLLMManagerCore

final class LaunchPreflightErrorTests: XCTestCase {
    func testRuntimeFileMissingDescriptionPointsToExistingBinary() {
        XCTAssertEqual(
            LaunchPreflightError.runtimeFileMissing("/Users/kei/bin/llama-server").errorDescription,
            "Runtime executable does not exist. Choose an existing llama-server binary before starting. Current path: /Users/kei/bin/llama-server."
        )
    }

    func testRuntimePathIsDirectoryDescriptionPointsToBinaryFile() {
        XCTAssertEqual(
            LaunchPreflightError.runtimePathIsDirectory("/Users/kei/bin/llama-server").errorDescription,
            "Runtime executable path is a directory. Choose the llama-server binary file before starting. Current path: /Users/kei/bin/llama-server."
        )
    }

    func testRuntimeNotExecutableDescriptionPointsToBinaryAndPermissions() {
        XCTAssertEqual(
            LaunchPreflightError.runtimeNotExecutable("/Users/kei/bin/llama-server").errorDescription,
            "Runtime executable is not executable. Choose the llama-server binary file and check file permissions. Current path: /Users/kei/bin/llama-server."
        )
    }

    func testModelFileMissingDescriptionPointsToExistingGGUFModel() {
        XCTAssertEqual(
            LaunchPreflightError.modelFileMissing("/Users/kei/Models/qwen.gguf").errorDescription,
            "Model file does not exist. Choose an existing .gguf model before starting. Current path: /Users/kei/Models/qwen.gguf."
        )
    }

    func testModelPathIsDirectoryDescriptionPointsToGGUFModelFile() {
        XCTAssertEqual(
            LaunchPreflightError.modelPathIsDirectory("/Users/kei/Models/qwen.gguf").errorDescription,
            "Model path is a directory. Choose an existing .gguf model file before starting. Current path: /Users/kei/Models/qwen.gguf."
        )
    }

    func testPortUnavailableDescriptionPointsToDifferentPort() {
        XCTAssertEqual(
            LaunchPreflightError.portUnavailable(1234).errorDescription,
            "Port 1234 is already in use. Choose a different port before starting."
        )
    }
}
