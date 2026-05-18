import XCTest
@testable import HazakuraLLMManagerCore

final class ServerStatusTests: XCTestCase {
    func testStatusTitlesDescribeRestartSeparatelyFromStop() {
        XCTAssertEqual(ServerStatus.stopped.title, "Stopped")
        XCTAssertEqual(ServerStatus.starting.title, "Starting")
        XCTAssertEqual(ServerStatus.running.title, "Running")
        XCTAssertEqual(ServerStatus.stopping.title, "Stopping")
        XCTAssertEqual(ServerStatus.restarting.title, "Restarting")
        XCTAssertEqual(ServerStatus.error.title, "Error")
    }
}
