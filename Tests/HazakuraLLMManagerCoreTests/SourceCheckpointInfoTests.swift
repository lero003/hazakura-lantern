import XCTest
@testable import HazakuraLLMManagerCore

final class SourceCheckpointInfoTests: XCTestCase {
    func testCurrentCheckpointStaysSourceOnly() {
        XCTAssertEqual(SourceCheckpointInfo.current.identifier, "v1.0.0-rc.2")
        XCTAssertFalse(SourceCheckpointInfo.current.includesPackagedAppArtifact)
    }
}
