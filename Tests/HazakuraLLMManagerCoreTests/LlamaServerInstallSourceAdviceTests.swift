import XCTest
@testable import HazakuraLLMManagerCore

final class LlamaServerInstallSourceAdviceTests: XCTestCase {
    func testClassifyReturnsNilForBlankPath() {
        XCTAssertNil(LlamaServerInstallSourceAdvice.classify(executablePath: "  "))
    }

    func testClassifyRecognizesHomebrewStylePath() throws {
        for executablePath in [
            "/opt/homebrew/bin/llama-server",
            "/usr/local/bin/llama-server"
        ] {
            let advice = try XCTUnwrap(
                LlamaServerInstallSourceAdvice.classify(
                    executablePath: executablePath
                )
            )

            XCTAssertEqual(advice.source, .homebrew)
            XCTAssertEqual(advice.title, "Runtime source: Homebrew-style path")
            XCTAssertTrue(advice.detail.contains("updates stay outside the app"))
        }
    }

    func testClassifyRecognizesMacPortsStylePath() throws {
        let advice = try XCTUnwrap(
            LlamaServerInstallSourceAdvice.classify(
                executablePath: "/opt/local/bin/llama-server"
            )
        )

        XCTAssertEqual(advice.source, .macPorts)
        XCTAssertTrue(advice.detail.contains("will not run package-manager updates"))
    }

    func testClassifyRecognizesSourceCheckoutPath() throws {
        let advice = try XCTUnwrap(
            LlamaServerInstallSourceAdvice.classify(
                executablePath: "/Users/kei/Code/llama.cpp/build/bin/llama-server"
            )
        )

        XCTAssertEqual(advice.source, .sourceCheckout)
        XCTAssertTrue(advice.detail.contains("rebuilding or updating the checkout stays manual"))
    }

    func testClassifyFallsBackToManualPath() throws {
        let advice = try XCTUnwrap(
            LlamaServerInstallSourceAdvice.classify(
                executablePath: "/Users/kei/bin/llama-server"
            )
        )

        XCTAssertEqual(advice.source, .manualPath)
        XCTAssertTrue(advice.detail.contains("keep updates manual and visible"))
    }
}
