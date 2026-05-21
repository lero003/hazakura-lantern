import XCTest
@testable import HazakuraLLMManagerCore

final class SourceCheckpointInfoTests: XCTestCase {
    func testCurrentCheckpointStaysSourceOnly() {
        XCTAssertEqual(SourceCheckpointInfo.current.identifier, "v0.9.0-alpha.1")
        XCTAssertFalse(SourceCheckpointInfo.current.includesPackagedAppArtifact)
    }
}
