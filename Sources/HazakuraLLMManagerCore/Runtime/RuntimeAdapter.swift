import Foundation

public protocol RuntimeAdapter {
    var id: String { get }
    var displayName: String { get }
    var supportedModelTypes: [String] { get }

    func validate(config: RuntimeConfiguration) throws
    func validateLaunchPreconditions(config: RuntimeConfiguration, fileManager: FileManager) throws
    func buildLaunchCommand(config: RuntimeConfiguration) throws -> LaunchCommand
    func endpoint(config: RuntimeConfiguration) throws -> RuntimeEndpoint
    func describeLaunchProcessFailure(_ error: Error, command: LaunchCommand) -> String
}

public extension RuntimeAdapter {
    func validateLaunchPreconditions(config: RuntimeConfiguration, fileManager: FileManager) throws {
        try validate(config: config)
    }

    func healthCheckURL(config: RuntimeConfiguration) throws -> URL? {
        try endpoint(config: config).healthCheckURL
    }

    func apiBaseURL(config: RuntimeConfiguration) throws -> URL {
        try endpoint(config: config).apiBaseURL
    }

    func describeLaunchProcessFailure(_ error: Error, command: LaunchCommand) -> String {
        LaunchProcessFailureMessage.describe(
            error,
            command: command,
            runtimeExecutableName: displayName,
            fallbackRecoveryHint: "Check the selected runtime configuration, then try again."
        )
    }
}
