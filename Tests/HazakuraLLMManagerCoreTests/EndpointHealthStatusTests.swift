import XCTest
@testable import HazakuraLLMManagerCore

final class EndpointHealthStatusTests: XCTestCase {
    func testPresentationForUncheckedStatus() {
        let status = EndpointHealthStatus.unchecked

        XCTAssertEqual(status.title, "Not checked")
        XCTAssertEqual(status.detail, "Run a manual check after the server is started.")
        XCTAssertEqual(status.systemImageName, "questionmark.circle")
        XCTAssertEqual(status.tone, .neutral)
    }

    func testPresentationForCheckingStatus() {
        let status = EndpointHealthStatus.checking

        XCTAssertEqual(status.title, "Checking")
        XCTAssertEqual(status.detail, "Requesting the local health endpoint...")
        XCTAssertEqual(status.systemImageName, "clock")
        XCTAssertEqual(status.tone, .inProgress)
    }

    func testPresentationForHealthyStatus() {
        let status = EndpointHealthStatus.healthy(statusCode: 200)

        XCTAssertEqual(status.title, "Healthy (HTTP 200)")
        XCTAssertEqual(status.detail, "Manual health check passed. This is a snapshot, not automatic polling.")
        XCTAssertEqual(status.systemImageName, "checkmark.circle")
        XCTAssertEqual(status.tone, .success)
    }

    func testPresentationForUnhealthyStatusKeepsFailureMessage() {
        let message = "No server responded at http://localhost:1234/v1/models."
        let status = EndpointHealthStatus.unhealthy(message: message)

        XCTAssertEqual(status.title, "Unhealthy")
        XCTAssertEqual(status.detail, message)
        XCTAssertEqual(status.systemImageName, "exclamationmark.triangle")
        XCTAssertEqual(status.tone, .failure)
    }
}
