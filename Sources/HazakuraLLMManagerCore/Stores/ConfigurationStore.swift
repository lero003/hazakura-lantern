import Foundation

public final class ConfigurationStore {
    private static let recentPathLimit = 8
    private static let defaultRuntimeProfileName = "Default runtime"

    private let defaults: UserDefaults
    private let key = "dev.hazakura.llmmanager.runtimeConfiguration.v1"
    private let runtimeProfileKey = "dev.hazakura.llmmanager.runtimeProfile.v1"
    private let recentPathsKey = "dev.hazakura.llmmanager.recentRuntimePaths.v1"
    private let ggufDownloadDirectoryKey = "dev.hazakura.llmmanager.ggufDownloadDirectory.v1"

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

    public func loadRuntimeProfile() -> RuntimeProfileDocument {
        loadRuntimeProfile(named: Self.defaultRuntimeProfileName)
    }

    public func loadRuntimeProfile(named fallbackName: String) -> RuntimeProfileDocument {
        guard let data = defaults.data(forKey: runtimeProfileKey) else {
            return RuntimeProfileDocument(name: fallbackName, configuration: load())
        }

        do {
            return try RuntimeProfileDocument.importJSONData(data)
        } catch {
            return RuntimeProfileDocument(name: fallbackName, configuration: load())
        }
    }

    public func saveRuntimeProfile(_ profile: RuntimeProfileDocument) {
        guard let data = try? profile.exportJSONData() else {
            return
        }

        defaults.set(data, forKey: runtimeProfileKey)
        save(profile.configuration)
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

    public func loadGGUFDownloadDirectory() -> String {
        defaults.string(forKey: ggufDownloadDirectoryKey) ?? ""
    }

    public func saveGGUFDownloadDirectory(_ path: String) {
        let trimmed = path.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty {
            defaults.removeObject(forKey: ggufDownloadDirectoryKey)
        } else {
            defaults.set(trimmed, forKey: ggufDownloadDirectoryKey)
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
