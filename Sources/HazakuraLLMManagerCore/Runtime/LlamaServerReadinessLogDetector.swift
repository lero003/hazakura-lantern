import Foundation

public enum LlamaServerReadinessLogDetector {
    public static func isReadyLog(_ text: String) -> Bool {
        let lowercasedText = text.lowercased()
        let readinessMarkers = [
            "server is listening",
            "listening on http",
            "http server listening",
            "server listening"
        ]

        return readinessMarkers.contains { lowercasedText.contains($0) }
    }
}
