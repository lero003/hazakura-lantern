import XCTest
@testable import HazakuraLLMManagerCore

final class LlamaServerReadinessLogDetectorTests: XCTestCase {
    func testDetectsKnownReadinessLogMessages() {
        XCTAssertTrue(LlamaServerReadinessLogDetector.isReadyLog("main: server is listening on http://127.0.0.1:1234"))
        XCTAssertTrue(LlamaServerReadinessLogDetector.isReadyLog("HTTP server listening at http://localhost:1234"))
        XCTAssertTrue(LlamaServerReadinessLogDetector.isReadyLog("server listening on 127.0.0.1:1234"))
    }

    func testIgnoresProgressLogsBeforeReadiness() {
        XCTAssertFalse(LlamaServerReadinessLogDetector.isReadyLog("llama_model_loader: loaded meta data with 42 key-value pairs"))
        XCTAssertFalse(LlamaServerReadinessLogDetector.isReadyLog("main: loading model"))
    }
}
