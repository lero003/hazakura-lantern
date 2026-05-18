import Foundation
import XCTest
@testable import HazakuraLLMManagerCore

final class RuntimeAdapterTests: XCTestCase {
    func testDefaultLaunchFailureDescriptionDoesNotAssumeLlamaServer() {
        let error = NSError(
            domain: "LanternTest",
            code: 42,
            userInfo: [NSLocalizedDescriptionKey: "Unexpected launch failure"]
        )
        let command = LaunchCommand(
            executablePath: "/Users/kei/bin/custom-runtime",
            arguments: []
        )

        let message = MinimalAdapter().describeLaunchProcessFailure(error, command: command)

        XCTAssertEqual(
            message,
            "Runtime process could not start. Check the selected runtime configuration, then try again. System error: Unexpected launch failure."
        )
    }
}

private struct MinimalAdapter: RuntimeAdapter {
    let id = "minimal"
    let displayName = "minimal runtime"
    let supportedModelTypes: [String] = []

    func validate(config: RuntimeConfiguration) throws {}
    func buildLaunchCommand(config: RuntimeConfiguration) throws -> LaunchCommand {
        LaunchCommand(executablePath: "/Users/kei/bin/custom-runtime", arguments: [])
    }

    func endpoint(config: RuntimeConfiguration) throws -> RuntimeEndpoint {
        RuntimeEndpoint(
            apiBaseURL: URL(string: "http://localhost:1234/v1")!,
            healthCheckURL: nil
        )
    }
}
