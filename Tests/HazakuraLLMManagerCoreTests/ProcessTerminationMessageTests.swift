import Foundation
import XCTest
@testable import HazakuraLLMManagerCore

final class ProcessTerminationMessageTests: XCTestCase {
    func testExitReasonDescribesExitCode() {
        XCTAssertEqual(
            ProcessTerminationMessage.describe(status: 0, reason: .exit),
            "Process exited with code 0."
        )
    }

    func testSignalReasonDescribesSignal() {
        XCTAssertEqual(
            ProcessTerminationMessage.describe(status: 15, reason: .uncaughtSignal),
            "Process terminated by signal 15."
        )
    }
}
