import XCTest
@testable import HazakuraLLMManagerCore

final class SourceCheckpointInfoTests: XCTestCase {
    func testCurrentCheckpointIncludesWarningExpectedPreviewArtifact() {
        XCTAssertEqual(SourceCheckpointInfo.current.identifier, "v1.7.1")
        XCTAssertTrue(SourceCheckpointInfo.current.includesPackagedAppArtifact)
    }
}
