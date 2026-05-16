import Foundation

public protocol RuntimeAdapter {
    var id: String { get }
    var displayName: String { get }
    var supportedModelTypes: [String] { get }

    func buildLaunchCommand(config: RuntimeConfiguration) throws -> LaunchCommand
    func healthCheckURL(config: RuntimeConfiguration) -> URL?
    func apiBaseURL(config: RuntimeConfiguration) -> URL
}
