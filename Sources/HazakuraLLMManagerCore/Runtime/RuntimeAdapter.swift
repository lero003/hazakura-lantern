import Foundation

public protocol RuntimeAdapter {
    var id: String { get }
    var displayName: String { get }
    var supportedModelTypes: [String] { get }

    func buildLaunchCommand(config: RuntimeConfiguration) throws -> LaunchCommand
    func endpoint(config: RuntimeConfiguration) -> RuntimeEndpoint
}

public extension RuntimeAdapter {
    func healthCheckURL(config: RuntimeConfiguration) -> URL? {
        endpoint(config: config).healthCheckURL
    }

    func apiBaseURL(config: RuntimeConfiguration) -> URL {
        endpoint(config: config).apiBaseURL
    }
}
