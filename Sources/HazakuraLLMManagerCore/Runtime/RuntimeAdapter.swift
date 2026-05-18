import Foundation

public protocol RuntimeAdapter {
    var id: String { get }
    var displayName: String { get }
    var supportedModelTypes: [String] { get }

    func validate(config: RuntimeConfiguration) throws
    func buildLaunchCommand(config: RuntimeConfiguration) throws -> LaunchCommand
    func endpoint(config: RuntimeConfiguration) throws -> RuntimeEndpoint
}

public extension RuntimeAdapter {
    func healthCheckURL(config: RuntimeConfiguration) throws -> URL? {
        try endpoint(config: config).healthCheckURL
    }

    func apiBaseURL(config: RuntimeConfiguration) throws -> URL {
        try endpoint(config: config).apiBaseURL
    }
}
