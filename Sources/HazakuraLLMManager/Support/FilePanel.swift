import AppKit
import UniformTypeIdentifiers

enum FilePanel {
    static func chooseFile(allowedExtensions: [String]? = nil) -> String? {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        panel.resolvesAliases = true

        if let allowedExtensions {
            panel.allowedContentTypes = allowedExtensions.compactMap { UTType(filenameExtension: $0) }
        }

        return panel.runModal() == .OK ? panel.url?.path : nil
    }
}
