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

    func testRequestedStopDescribesExpectedSignalWithoutUnexpectedTerminationWording() {
        XCTAssertEqual(
            ProcessTerminationMessage.describe(
                status: 15,
                reason: .uncaughtSignal,
                requestedAction: .stop
            ),
            "Stop request completed with signal 15."
        )
    }

    func testRequestedRestartDescribesCurrentProcessStop() {
        XCTAssertEqual(
            ProcessTerminationMessage.describe(
                status: 15,
                reason: .uncaughtSignal,
                requestedAction: .restart
            ),
            "Restart request stopped the current process with signal 15."
        )
    }
}
