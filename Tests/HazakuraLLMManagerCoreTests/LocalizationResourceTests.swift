import Foundation
import XCTest

final class LocalizationResourceTests: XCTestCase {
    func testLocalizedResourcesDoNotDeclareDuplicateKeys() throws {
        for resource in localizationResources {
            let entries = try localizedEntries(in: resource.url)
            let duplicatedKeys = Dictionary(grouping: entries, by: \.key)
                .compactMap { key, entries -> String? in
                    guard entries.count > 1 else { return nil }
                    let lines = entries.map(\.line).map(String.init).joined(separator: ", ")
                    return "\(key) at lines \(lines)"
                }
                .sorted()

            XCTAssertEqual(
                duplicatedKeys,
                [],
                "\(resource.name) should not declare duplicate localization keys"
            )
        }
    }

    func testEnglishAndJapaneseLocalizationKeysStayInParity() throws {
        let englishKeys = Set(try localizedEntries(in: resourceURL("en.lproj")).map(\.key))
        let japaneseKeys = Set(try localizedEntries(in: resourceURL("ja.lproj")).map(\.key))

        XCTAssertEqual(
            englishKeys.subtracting(japaneseKeys).sorted(),
            [],
            "Japanese localization should include every English key"
        )
        XCTAssertEqual(
            japaneseKeys.subtracting(englishKeys).sorted(),
            [],
            "English localization should include every Japanese key"
        )
    }

    func testEnglishAndJapaneseFormatPlaceholdersStayInParity() throws {
        let englishEntries = try localizedEntriesByKey(in: resourceURL("en.lproj"))
        let japaneseEntries = try localizedEntriesByKey(in: resourceURL("ja.lproj"))
        let sharedKeys = Set(englishEntries.keys).intersection(japaneseEntries.keys)

        let mismatches = sharedKeys.compactMap { key -> String? in
            guard let englishValue = englishEntries[key]?.value,
                  let japaneseValue = japaneseEntries[key]?.value
            else { return nil }

            let englishPlaceholders = formatPlaceholders(in: englishValue)
            let japanesePlaceholders = formatPlaceholders(in: japaneseValue)

            guard englishPlaceholders != japanesePlaceholders else {
                return nil
            }

            return "\(key): en \(englishPlaceholders), ja \(japanesePlaceholders)"
        }
        .sorted()

        XCTAssertEqual(
            mismatches,
            [],
            "English and Japanese localization values should keep matching format placeholders"
        )
    }

    private struct LocalizationEntry {
        let key: String
        let value: String
        let line: Int
    }

    private var localizationResources: [(name: String, url: URL)] {
        [
            ("English Localizable.strings", resourceURL("en.lproj")),
            ("Japanese Localizable.strings", resourceURL("ja.lproj"))
        ]
    }

    private func localizedEntriesByKey(in url: URL) throws -> [String: LocalizationEntry] {
        try localizedEntries(in: url).reduce(into: [:]) { result, entry in
            if result[entry.key] == nil {
                result[entry.key] = entry
            }
        }
    }

    private func localizedEntries(in url: URL) throws -> [LocalizationEntry] {
        let contents = try String(contentsOf: url, encoding: .utf8)
        var entries: [LocalizationEntry] = []

        for (offset, line) in contents.split(separator: "\n", omittingEmptySubsequences: false).enumerated() {
            guard let entry = localizationEntry(in: String(line), line: offset + 1) else { continue }
            entries.append(entry)
        }

        return entries
    }

    private func localizationEntry(in line: String, line lineNumber: Int) -> LocalizationEntry? {
        let trimmed = line.trimmingCharacters(in: .whitespaces)
        guard trimmed.hasPrefix("\"") else { return nil }
        guard let key = quotedString(in: trimmed, startingAt: trimmed.startIndex) else { return nil }
        guard let separatorRange = trimmed[key.nextIndex...].range(of: "=") else { return nil }

        let valueStart = trimmed[separatorRange.upperBound...]
            .firstIndex(where: { !$0.isWhitespace })
        guard let valueStart,
              let value = quotedString(in: trimmed, startingAt: valueStart)
        else { return nil }

        return LocalizationEntry(key: key.value, value: value.value, line: lineNumber)
    }

    private func quotedString(in line: String, startingAt startIndex: String.Index) -> (value: String, nextIndex: String.Index)? {
        guard startIndex < line.endIndex, line[startIndex] == "\"" else { return nil }
        var key = ""
        var isEscaped = false

        var currentIndex = line.index(after: startIndex)
        while currentIndex < line.endIndex {
            let character = line[currentIndex]

            if isEscaped {
                key.append(character)
                isEscaped = false
                currentIndex = line.index(after: currentIndex)
                continue
            }

            if character == "\\" {
                isEscaped = true
                currentIndex = line.index(after: currentIndex)
                continue
            }

            if character == "\"" {
                return (key, line.index(after: currentIndex))
            }

            key.append(character)
            currentIndex = line.index(after: currentIndex)
        }

        return nil
    }

    private func formatPlaceholders(in value: String) -> [String] {
        let pattern = #"%(?:(\d+)\$)?[-+ #0]*(?:\d+|\*)?(?:\.(?:\d+|\*))?(?:hh|h|ll|l|q|L|z|t|j)?[@diuoxXfFeEgGaAcCsSp]"#
        let regex = try! NSRegularExpression(pattern: pattern)
        let range = NSRange(value.startIndex..<value.endIndex, in: value)

        return regex.matches(in: value, range: range).compactMap { match in
            guard let matchRange = Range(match.range, in: value) else { return nil }
            return value[matchRange].last.map(String.init)
        }
    }

    private func resourceURL(_ localizationDirectory: String) -> URL {
        packageRoot
            .appendingPathComponent("Sources/HazakuraLLMManager/Resources")
            .appendingPathComponent(localizationDirectory)
            .appendingPathComponent("Localizable.strings")
    }

    private var packageRoot: URL {
        URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
    }
}
