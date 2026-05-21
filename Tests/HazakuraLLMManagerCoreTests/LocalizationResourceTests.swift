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

    private struct LocalizationEntry {
        let key: String
        let line: Int
    }

    private var localizationResources: [(name: String, url: URL)] {
        [
            ("English Localizable.strings", resourceURL("en.lproj")),
            ("Japanese Localizable.strings", resourceURL("ja.lproj"))
        ]
    }

    private func localizedEntries(in url: URL) throws -> [LocalizationEntry] {
        let contents = try String(contentsOf: url, encoding: .utf8)
        var entries: [LocalizationEntry] = []

        for (offset, line) in contents.split(separator: "\n", omittingEmptySubsequences: false).enumerated() {
            guard let key = localizationKey(in: String(line)) else { continue }
            entries.append(LocalizationEntry(key: key, line: offset + 1))
        }

        return entries
    }

    private func localizationKey(in line: String) -> String? {
        let trimmed = line.trimmingCharacters(in: .whitespaces)
        guard trimmed.hasPrefix("\"") else { return nil }

        var key = ""
        var isEscaped = false

        for character in trimmed.dropFirst() {
            if isEscaped {
                key.append(character)
                isEscaped = false
                continue
            }

            if character == "\\" {
                isEscaped = true
                continue
            }

            if character == "\"" {
                return key
            }

            key.append(character)
        }

        return nil
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
