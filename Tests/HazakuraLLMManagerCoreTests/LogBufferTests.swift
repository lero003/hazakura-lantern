import XCTest
@testable import HazakuraLLMManagerCore

final class LogBufferTests: XCTestCase {
    func testAppendSplitsMultilineTextIntoEntries() {
        var buffer = LogBuffer(maxEntries: 10)

        buffer.append("first line\nsecond line\n", stream: .stdout)

        XCTAssertEqual(buffer.entries.map(\.text), ["first line", "second line"])
        XCTAssertEqual(buffer.entries.map(\.stream), [.stdout, .stdout])
    }

    func testAppendKeepsSingleEmptyOrWhitespaceOnlyEntry() {
        var buffer = LogBuffer(maxEntries: 10)

        buffer.append("\n", stream: .stderr)

        XCTAssertEqual(buffer.entries.map(\.text), ["\n"])
        XCTAssertEqual(buffer.entries.map(\.stream), [.stderr])
    }

    func testAppendTrimsOldestEntriesAtLimit() {
        var buffer = LogBuffer(maxEntries: 3)

        buffer.append("one\ntwo\nthree\nfour", stream: .info)

        XCTAssertEqual(buffer.entries.map(\.text), ["two", "three", "four"])
    }

    func testClearRemovesAllEntries() {
        var buffer = LogBuffer(maxEntries: 3)
        buffer.append("one\ntwo", stream: .error)

        buffer.clear()

        XCTAssertTrue(buffer.entries.isEmpty)
    }
}
