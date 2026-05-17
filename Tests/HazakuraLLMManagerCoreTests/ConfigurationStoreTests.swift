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
