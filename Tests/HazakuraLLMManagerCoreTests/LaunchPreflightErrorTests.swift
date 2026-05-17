import XCTest
@testable import HazakuraLLMManagerCore

final class LaunchPreflightErrorTests: XCTestCase {
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
}
