import Foundation
import SwiftUI

enum AppLanguage: String, CaseIterable, Identifiable {
    case system
    case japanese
    case english

    static let storageKey = "dev.hazakura.llmmanager.uiLanguage.v1"

    var id: String { rawValue }

    var titleKey: LocalizedStringKey {
        switch self {
        case .system:
            return "System"
        case .japanese:
            return "Japanese"
        case .english:
            return "English"
        }
    }

    var locale: Locale {
        switch self {
        case .system:
            return .autoupdatingCurrent
        case .japanese:
            return Locale(identifier: "ja")
        case .english:
            return Locale(identifier: "en")
        }
    }
}
