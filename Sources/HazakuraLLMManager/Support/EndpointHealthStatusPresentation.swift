import Foundation
import HazakuraLLMManagerCore

extension EndpointHealthStatus {
    var localizedTitle: String {
        switch self {
        case .unchecked:
            localized("endpoint_health.unchecked.title")
        case .checking:
            localized("endpoint_health.checking.title")
        case .healthy(let statusCode):
            String(
                format: localized("endpoint_health.healthy.title"),
                statusCode
            )
        case .unhealthy:
            localized("endpoint_health.unhealthy.title")
        }
    }

    var localizedDetail: String? {
        switch self {
        case .unchecked:
            localized("endpoint_health.unchecked.detail")
        case .checking:
            localized("endpoint_health.checking.detail")
        case .healthy:
            localized("endpoint_health.healthy.detail")
        case .unhealthy(let message):
            message
        }
    }

    var localizedAccessibilityValue: String {
        if let localizedDetail {
            "\(localizedTitle). \(localizedDetail)"
        } else {
            localizedTitle
        }
    }

    private func localized(_ key: String.LocalizationValue) -> String {
        String(localized: key, bundle: .module)
    }
}
