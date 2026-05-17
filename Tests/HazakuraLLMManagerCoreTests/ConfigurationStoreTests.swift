import XCTest
@testable import HazakuraLLMManagerCore

final class ConfigurationStoreTests: XCTestCase {
    func testSaveAndLoadRoundTrip() {
        let (defaults, suiteName) = makeDefaults()
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let store = ConfigurationStore(defaults: defaults)
        let config = RuntimeConfiguration(
            runtimeExecutablePath: "/tmp/llama-server",
            modelPath: "/tmp/model.gguf",
            host: "127.0.0.1",
            port: 4567,
            contextSize: 4096,
            threads: "4",
            gpuLayers: "auto",
            additionalArguments: "--verbose"
        )

        store.save(config)

        XCTAssertEqual(store.load(), config)
    }

    func testRuntimeProfileFallsBackToCurrentConfigurationWhenNoProfileIsSaved() {
        let (defaults, suiteName) = makeDefaults()
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let store = ConfigurationStore(defaults: defaults)
        let config = RuntimeConfiguration(
            runtimeExecutablePath: "/tmp/llama-server",
            modelPath: "/tmp/model.gguf",
            host: "127.0.0.1",
            port: 4567,
            contextSize: 4096,
            threads: "4",
            gpuLayers: "auto",
            additionalArguments: "--verbose"
        )

        store.save(config)

        let profile = store.loadRuntimeProfile(named: "Recovered runtime")

        XCTAssertEqual(profile.name, "Recovered runtime")
        XCTAssertEqual(profile.runtimeKind, "llama-server")
        XCTAssertEqual(profile.configuration, config)
    }

    func testRuntimeProfileSaveRoundTripsAndKeepsActiveConfigurationInSync() {
        let (defaults, suiteName) = makeDefaults()
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let store = ConfigurationStore(defaults: defaults)
        let profile = RuntimeProfileDocument(
            name: "Desk runtime",
            configuration: RuntimeConfiguration(
                runtimeExecutablePath: "/opt/llama.cpp/llama-server",
                modelPath: "/models/hazakura.gguf",
                host: "127.0.0.1",
                port: 4321,
                contextSize: 8192,
                threads: "6",
                gpuLayers: "0",
                additionalArguments: "--verbose"
            )
        )

        store.saveRuntimeProfile(profile)

        XCTAssertEqual(store.loadRuntimeProfile(), profile)
        XCTAssertEqual(store.load(), profile.configuration)
    }

    func testUnsupportedRuntimeProfileFallsBackToCurrentConfiguration() {
        let (defaults, suiteName) = makeDefaults()
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let store = ConfigurationStore(defaults: defaults)
        let config = RuntimeConfiguration(
            runtimeExecutablePath: "/tmp/llama-server",
            modelPath: "/tmp/model.gguf",
            host: "127.0.0.1",
            port: 4567,
            contextSize: 4096,
            threads: "4",
            gpuLayers: "auto",
            additionalArguments: "--verbose"
        )
        let futureProfileJSON = """
        {
          "schemaVersion": 2,
          "name": "Future runtime",
          "runtimeKind": "llama-server",
          "configuration": {
            "runtimeExecutablePath": "/future/llama-server",
            "modelPath": "/future/model.gguf",
            "host": "127.0.0.1",
            "port": 9876,
            "contextSize": 8192,
            "threads": "8",
            "gpuLayers": "0",
            "additionalArguments": "--future"
          }
        }
        """

        store.save(config)
        defaults.set(
            Data(futureProfileJSON.utf8),
            forKey: "dev.hazakura.llmmanager.runtimeProfile.v1"
        )

        let profile = store.loadRuntimeProfile(named: "Recovered runtime")

        XCTAssertEqual(profile.name, "Recovered runtime")
        XCTAssertEqual(profile.schemaVersion, RuntimeProfileDocument.currentSchemaVersion)
        XCTAssertEqual(profile.configuration, config)
    }

    func testUnsupportedRuntimeKindProfileFallsBackToCurrentConfiguration() {
        let (defaults, suiteName) = makeDefaults()
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let store = ConfigurationStore(defaults: defaults)
        let config = RuntimeConfiguration(
            runtimeExecutablePath: "/tmp/llama-server",
            modelPath: "/tmp/model.gguf",
            host: "127.0.0.1",
            port: 4567,
            contextSize: 4096,
            threads: "4",
            gpuLayers: "auto",
            additionalArguments: "--verbose"
        )
        let unsupportedRuntimeKindProfileJSON = """
        {
          "schemaVersion": 1,
          "name": "Other runtime",
          "runtimeKind": "ollama",
          "configuration": {
            "runtimeExecutablePath": "/opt/ollama",
            "modelPath": "/future/model.gguf",
            "host": "127.0.0.1",
            "port": 9876,
            "contextSize": 8192,
            "threads": "8",
            "gpuLayers": "0",
            "additionalArguments": "--future"
          }
        }
        """

        store.save(config)
        defaults.set(
            Data(unsupportedRuntimeKindProfileJSON.utf8),
            forKey: "dev.hazakura.llmmanager.runtimeProfile.v1"
        )

        let profile = store.loadRuntimeProfile(named: "Recovered runtime")

        XCTAssertEqual(profile.name, "Recovered runtime")
        XCTAssertEqual(profile.schemaVersion, RuntimeProfileDocument.currentSchemaVersion)
        XCTAssertEqual(profile.configuration, config)
    }

    func testRecentPathsDeduplicateAndKeepNewestFirst() {
        let (defaults, suiteName) = makeDefaults()
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let store = ConfigurationStore(defaults: defaults)

        store.recordRuntimeExecutablePath("/opt/llama.cpp/llama-server")
        store.recordRuntimeExecutablePath("/usr/local/bin/llama-server")
        store.recordRuntimeExecutablePath("/opt/llama.cpp/llama-server")
        store.recordModelPath("/models/qwen.gguf")
        store.recordModelPath("  ")

        XCTAssertEqual(
            store.loadRecentPaths().runtimeExecutablePaths,
            [
                "/opt/llama.cpp/llama-server",
                "/usr/local/bin/llama-server"
            ]
        )
        XCTAssertEqual(store.loadRecentPaths().modelPaths, ["/models/qwen.gguf"])
    }

    func testRecentPathsAreCapped() {
        let (defaults, suiteName) = makeDefaults()
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let store = ConfigurationStore(defaults: defaults)

        for index in 0..<12 {
            store.recordModelPath("/models/model-\(index).gguf")
        }

        XCTAssertEqual(store.loadRecentPaths().modelPaths.count, 8)
        XCTAssertEqual(store.loadRecentPaths().modelPaths.first, "/models/model-11.gguf")
        XCTAssertEqual(store.loadRecentPaths().modelPaths.last, "/models/model-4.gguf")
    }

    private func makeDefaults() -> (UserDefaults, String) {
        let suiteName = "HazakuraLLMManagerTests-\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        return (defaults, suiteName)
    }
}
