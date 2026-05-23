import XCTest
@testable import HazakuraLLMManagerCore

final class SourceCheckpointInfoTests: XCTestCase {
    func testCurrentCheckpointStaysSourceOnly() {
        XCTAssertEqual(SourceCheckpointInfo.current.identifier, "v1.2.0")
        XCTAssertFalse(SourceCheckpointInfo.current.includesPackagedAppArtifact)
    }
}
