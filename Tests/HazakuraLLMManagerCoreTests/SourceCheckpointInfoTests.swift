import XCTest
@testable import HazakuraLLMManagerCore

final class SourceCheckpointInfoTests: XCTestCase {
    func testCurrentCheckpointStaysSourceOnly() {
        XCTAssertEqual(SourceCheckpointInfo.current.identifier, "v1.5.0")
        XCTAssertFalse(SourceCheckpointInfo.current.includesPackagedAppArtifact)
    }
}
