import XCTest
@testable import HazakuraLLMManagerCore

final class CommandLineArgumentTokenizerTests: XCTestCase {
    func testTokenizesWhitespaceSeparatedArguments() throws {
        let arguments = try CommandLineArgumentTokenizer.tokenize("--verbose --temp 0.7")

        XCTAssertEqual(arguments, ["--verbose", "--temp", "0.7"])
    }

    func testTokenizesQuotedArguments() throws {
        let arguments = try CommandLineArgumentTokenizer.tokenize("--alias \"qwen local\" --flag='two words'")

        XCTAssertEqual(arguments, ["--alias", "qwen local", "--flag=two words"])
    }

    func testThrowsOnUnterminatedQuote() {
        XCTAssertThrowsError(try CommandLineArgumentTokenizer.tokenize("--alias \"qwen")) { error in
            XCTAssertEqual(error as? CommandLineArgumentTokenizerError, .unterminatedQuote("\""))
        }
    }
}
