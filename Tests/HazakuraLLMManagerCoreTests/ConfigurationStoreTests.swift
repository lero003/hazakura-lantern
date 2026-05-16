import XCTest
@testable import HazakuraLLMManagerCore

final class ConfigurationStoreTests: XCTestCase {
    func testSaveAndLoadRoundTrip() {
        let suiteName = "HazakuraLLMManagerTests-\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defer {
            defaults.removePersistentDomain(forName: suiteName)
        }

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
}
