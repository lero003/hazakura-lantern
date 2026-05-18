import Foundation
import XCTest
@testable import HazakuraLLMManagerCore

final class LaunchProcessFailureMessageTests: XCTestCase {
    func testMissingExecutableMessagePointsBackToRuntimeSelection() {
        let message = LaunchProcessFailureMessage.describe(
            posixError(.ENOENT, description: "No such file or directory"),
            command: command,
            runtimeExecutableName: "llama-server binary",
            fallbackRecoveryHint: llamaServerFallbackHint
        )

        XCTAssertEqual(
            message,
            "Runtime process could not start because macOS could not find the executable at /Users/kei/bin/llama-server. Choose an existing llama-server binary and start again. System error: No such file or directory."
        )
    }

    func testPermissionDeniedMessagePointsToExecutablePermission() {
        let message = LaunchProcessFailureMessage.describe(
            posixError(.EACCES, description: "Permission denied"),
            command: command,
            runtimeExecutableName: "llama-server binary",
            fallbackRecoveryHint: llamaServerFallbackHint
        )

        XCTAssertEqual(
            message,
            "Runtime process could not start because macOS refused permission for /Users/kei/bin/llama-server. Check that the llama-server binary is executable. System error: Permission denied."
        )
    }

    func testExecutableFormatMessagePointsToMacBinaryMismatch() {
        let message = LaunchProcessFailureMessage.describe(
            posixError(.ENOEXEC, description: "Exec format error"),
            command: command,
            runtimeExecutableName: "llama-server binary",
            fallbackRecoveryHint: llamaServerFallbackHint
        )

        XCTAssertEqual(
            message,
            "Runtime process could not start because macOS could not execute /Users/kei/bin/llama-server. Check that the selected path is a llama-server binary for this Mac. System error: Exec format error."
        )
    }

    func testFallbackMessageKeepsSystemErrorDetails() {
        let error = NSError(
            domain: "LanternTest",
            code: 42,
            userInfo: [NSLocalizedDescriptionKey: "Unexpected launch failure"]
        )

        let message = LaunchProcessFailureMessage.describe(
            error,
            command: command,
            runtimeExecutableName: "llama-server binary",
            fallbackRecoveryHint: llamaServerFallbackHint
        )

        XCTAssertEqual(
            message,
            "Runtime process could not start. Check the selected llama-server binary, model, and launch options, then try again. System error: Unexpected launch failure."
        )
    }

    private var command: LaunchCommand {
        LaunchCommand(
            executablePath: "/Users/kei/bin/llama-server",
            arguments: ["-m", "/Users/kei/Models/qwen.gguf"]
        )
    }

    private var llamaServerFallbackHint: String {
        "Check the selected llama-server binary, model, and launch options, then try again."
    }

    private func posixError(_ code: POSIXErrorCode, description: String) -> NSError {
        NSError(
            domain: NSPOSIXErrorDomain,
            code: Int(code.rawValue),
            userInfo: [NSLocalizedDescriptionKey: description]
        )
    }
}
