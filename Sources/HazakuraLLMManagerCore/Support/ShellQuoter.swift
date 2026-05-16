import Foundation

enum ShellQuoter {
    static func quote(_ value: String) -> String {
        guard !value.isEmpty else {
            return "''"
        }

        let safeCharacters = CharacterSet(charactersIn: "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789_+-=.,/:")
        if value.unicodeScalars.allSatisfy({ safeCharacters.contains($0) }) {
            return value
        }

        return "'" + value.replacingOccurrences(of: "'", with: "'\\''") + "'"
    }
}
