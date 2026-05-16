import Foundation

public final class ConfigurationStore {
    private let defaults: UserDefaults
    private let key = "dev.hazakura.llmmanager.runtimeConfiguration.v1"

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
}
