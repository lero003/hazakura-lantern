import XCTest
@testable import HazakuraLLMManagerCore

final class LaunchCommandTests: XCTestCase {
    func testDisplayStringQuotesUnsafeSegmentsForShellInspection() {
        let command = LaunchCommand(
            executablePath: "/Applications/llama server/bin/llama-server",
            arguments: [
                "--alias",
                "qwen local",
                "--note",
                "owner's model",
                ""
            ]
        )

        XCTAssertEqual(
            command.displayString,
            "'/Applications/llama server/bin/llama-server' --alias 'qwen local' --note 'owner'\\''s model' ''"
        )
    }
}
