import Foundation
import XCTest
@testable import HazakuraLLMManagerCore

final class RuntimeAdapterTests: XCTestCase {
    func testDefaultLaunchPreconditionsDelegateToValidation() {
        let adapter = MinimalAdapter()

        XCTAssertNoThrow(try adapter.validateLaunchPreconditions(config: .defaultValue, fileManager: .default))
    }

    func testDefaultLaunchPreconditionsPropagateValidationFailure() {
        let adapter = RejectingAdapter(error: RuntimeAdapterError.missingRuntimePath)

        XCTAssertThrowsError(try adapter.validateLaunchPreconditions(config: .defaultValue, fileManager: .default)) { error in
            XCTAssertEqual(error as? RuntimeAdapterError, .missingRuntimePath)
        }
    }

    func testDefaultEndpointHelpersProjectAdapterEndpoint() throws {
        let adapter = MinimalAdapter()
        let config = RuntimeConfiguration.defaultValue

        XCTAssertEqual(try adapter.apiBaseURL(config: config), URL(string: "http://localhost:1234/v1"))
        XCTAssertNil(try adapter.healthCheckURL(config: config))
    }

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

private struct RejectingAdapter: RuntimeAdapter {
    let id = "rejecting"
    let displayName = "rejecting runtime"
    let supportedModelTypes: [String] = []
    let error: Error

    func validate(config: RuntimeConfiguration) throws {
        throw error
    }

    func buildLaunchCommand(config: RuntimeConfiguration) throws -> LaunchCommand {
        LaunchCommand(executablePath: "/Users/kei/bin/rejecting-runtime", arguments: [])
    }

    func endpoint(config: RuntimeConfiguration) throws -> RuntimeEndpoint {
        RuntimeEndpoint(
            apiBaseURL: URL(string: "http://localhost:1234/v1")!,
            healthCheckURL: nil
        )
    }
}
