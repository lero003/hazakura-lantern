import Foundation

public enum CommandLineArgumentTokenizer {
    public static func tokenize(_ input: String) throws -> [String] {
        var arguments: [String] = []
        var current = ""
        var quote: Character?
        var isEscaping = false
        var tokenStarted = false

        for character in input {
            if isEscaping {
                current.append(character)
                tokenStarted = true
                isEscaping = false
                continue
            }

            if character == "\\" && quote != "'" {
                isEscaping = true
                tokenStarted = true
                continue
            }

            if let activeQuote = quote {
                if character == activeQuote {
                    quote = nil
                } else {
                    current.append(character)
                }
                tokenStarted = true
                continue
            }

            if character == "\"" || character == "'" {
                quote = character
                tokenStarted = true
                continue
            }

            if character.isShellWhitespace {
                if tokenStarted {
                    arguments.append(current)
                    current = ""
                    tokenStarted = false
                }
                continue
            }

            current.append(character)
            tokenStarted = true
        }

        if isEscaping {
            current.append("\\")
        }

        if let quote {
            throw CommandLineArgumentTokenizerError.unterminatedQuote(quote)
        }

        if tokenStarted {
            arguments.append(current)
        }

        return arguments
    }
}

public enum CommandLineArgumentTokenizerError: Error, Equatable, LocalizedError {
    case unterminatedQuote(Character)

    public var errorDescription: String? {
        switch self {
        case .unterminatedQuote(let quote):
            "Additional args contains an unterminated \(quote) quote."
        }
    }
}

private extension Character {
    var isShellWhitespace: Bool {
        unicodeScalars.allSatisfy { CharacterSet.whitespacesAndNewlines.contains($0) }
    }
}
