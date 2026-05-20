import XCTest
@testable import HazakuraLLMManagerCore

final class LlamaServerUpdateReadinessAdviceTests: XCTestCase {
    func testEvaluateReturnsNilForBlankPath() {
        XCTAssertNil(
            LlamaServerUpdateReadinessAdvice.evaluate(
                executablePath: " ",
                capabilityResult: nil
            )
        )
    }

    func testEvaluateRequiresCapabilityCheckForManagedSource() throws {
        let advice = try XCTUnwrap(
            LlamaServerUpdateReadinessAdvice.evaluate(
                executablePath: "/opt/homebrew/bin/llama-server",
                capabilityResult: nil
            )
        )

        XCTAssertEqual(advice.readiness, .needsCapabilityCheck)
        XCTAssertEqual(advice.title, "Update dry-run: check runtime first")
        XCTAssertTrue(advice.detail.contains("Run Check Runtime"))
        XCTAssertTrue(advice.detail.contains("local version and --help option evidence"))
    }

    func testEvaluateKeepsManualPathsManualOnly() throws {
        let advice = try XCTUnwrap(
            LlamaServerUpdateReadinessAdvice.evaluate(
                executablePath: "/Users/kei/bin/llama-server",
                capabilityResult: completeProbeResult()
            )
        )

        XCTAssertEqual(advice.readiness, .manualOnly)
        XCTAssertTrue(advice.detail.contains("cannot infer a safe updater"))
    }

    func testEvaluateRequiresCompleteCapabilityEvidence() throws {
        let advice = try XCTUnwrap(
            LlamaServerUpdateReadinessAdvice.evaluate(
                executablePath: "/opt/homebrew/bin/llama-server",
                capabilityResult: incompleteProbeResult()
            )
        )

        XCTAssertEqual(advice.readiness, .capabilityEvidenceIncomplete)
        XCTAssertTrue(advice.detail.contains("No update plan should be prepared yet"))
        XCTAssertTrue(advice.detail.contains("--version check timed out"))
    }

    func testEvaluateExplainsMissingHelpOptionEvidence() throws {
        let advice = try XCTUnwrap(
            LlamaServerUpdateReadinessAdvice.evaluate(
                executablePath: "/opt/local/bin/llama-server",
                capabilityResult: missingHelpOptionProbeResult()
            )
        )

        XCTAssertEqual(advice.readiness, .capabilityEvidenceIncomplete)
        XCTAssertTrue(advice.detail.contains("--help option list is unavailable"))
        XCTAssertTrue(advice.detail.contains("No update plan should be prepared yet"))
    }

    func testEvaluateReportsPlanningEvidenceForHomebrewStyleSource() throws {
        let advice = try XCTUnwrap(
            LlamaServerUpdateReadinessAdvice.evaluate(
                executablePath: "/opt/homebrew/bin/llama-server",
                capabilityResult: completeProbeResult()
            )
        )

        XCTAssertEqual(advice.readiness, .planningEvidenceReady)
        XCTAssertTrue(advice.detail.contains("llama-server version b4600"))
        XCTAssertTrue(advice.detail.contains("exact Homebrew command"))
        XCTAssertTrue(advice.detail.contains("require confirmation"))
    }

    func testEvaluateReportsPlanningEvidenceForSourceCheckout() throws {
        let advice = try XCTUnwrap(
            LlamaServerUpdateReadinessAdvice.evaluate(
                executablePath: "/Users/kei/Code/llama.cpp/build/bin/llama-server",
                capabilityResult: completeProbeResult()
            )
        )

        XCTAssertEqual(advice.readiness, .planningEvidenceReady)
        XCTAssertTrue(advice.detail.contains("exact checkout and build steps"))
    }

    private func completeProbeResult() -> LlamaServerCapabilityProbeResult {
        LlamaServerCapabilityProbeResult(
            versionCheck: .init(
                output: "llama-server version b4600",
                terminationStatus: 0,
                didTimeOut: false,
                errorDescription: nil
            ),
            helpCheck: .init(
                output: "--model FNAME\n--ctx-size N",
                terminationStatus: 0,
                didTimeOut: false,
                errorDescription: nil
            ),
            capabilities: .parse(
                versionOutput: "llama-server version b4600",
                helpOutput: "--model FNAME\n--ctx-size N"
            )
        )
    }

    private func incompleteProbeResult() -> LlamaServerCapabilityProbeResult {
        LlamaServerCapabilityProbeResult(
            versionCheck: .init(
                output: "",
                terminationStatus: nil,
                didTimeOut: true,
                errorDescription: nil
            ),
            helpCheck: .init(
                output: "--model FNAME",
                terminationStatus: 0,
                didTimeOut: false,
                errorDescription: nil
            ),
            capabilities: .parse(
                versionOutput: nil,
                helpOutput: "--model FNAME"
            )
        )
    }

    private func missingHelpOptionProbeResult() -> LlamaServerCapabilityProbeResult {
        LlamaServerCapabilityProbeResult(
            versionCheck: .init(
                output: "llama-server version b4600",
                terminationStatus: 0,
                didTimeOut: false,
                errorDescription: nil
            ),
            helpCheck: .init(
                output: "usage: llama-server\n",
                terminationStatus: 0,
                didTimeOut: false,
                errorDescription: nil
            ),
            capabilities: .parse(
                versionOutput: "llama-server version b4600",
                helpOutput: "usage: llama-server\n"
            )
        )
    }
}
