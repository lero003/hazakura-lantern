import Foundation

public final class ConfigurationStore {
    private static let recentPathLimit = 8

    private let defaults: UserDefaults
    private let key = "dev.hazakura.llmmanager.runtimeConfiguration.v1"
    private let recentPathsKey = "dev.hazakura.llmmanager.recentRuntimePaths.v1"

    public init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    public func load() -> RuntimeConfiguration {
        guard let data = defaults.data(forKey: key) else {
            return .defaultValue
        }

        do {
            return try JSONDecoder().decode(RuntimeConfiguration.self, from: data)
        } catch {
            return .defaultValue
        }
    }

    public func save(_ configuration: RuntimeConfiguration) {
        guard let data = try? JSONEncoder().encode(configuration) else {
            return
        }

        defaults.set(data, forKey: key)
    }

    public func loadRecentPaths() -> RecentRuntimePaths {
        guard let data = defaults.data(forKey: recentPathsKey) else {
            return .empty
        }

        do {
            return try JSONDecoder().decode(RecentRuntimePaths.self, from: data)
        } catch {
            return .empty
        }
    }

    @discardableResult
    public func recordRuntimeExecutablePath(_ path: String) -> RecentRuntimePaths {
        var recentPaths = loadRecentPaths()
        recentPaths.runtimeExecutablePaths = record(path, in: recentPaths.runtimeExecutablePaths)
        saveRecentPaths(recentPaths)
        return recentPaths
    }

    @discardableResult
    public func recordModelPath(_ path: String) -> RecentRuntimePaths {
        var recentPaths = loadRecentPaths()
        recentPaths.modelPaths = record(path, in: recentPaths.modelPaths)
        saveRecentPaths(recentPaths)
        return recentPaths
    }

    private func saveRecentPaths(_ recentPaths: RecentRuntimePaths) {
        guard let data = try? JSONEncoder().encode(recentPaths) else {
            return
        }

        defaults.set(data, forKey: recentPathsKey)
    }

    private func record(_ path: String, in paths: [String]) -> [String] {
        let trimmed = path.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            return paths
        }

        return ([trimmed] + paths.filter { $0 != trimmed })
            .prefix(Self.recentPathLimit)
            .map { $0 }
    }
}
