import Foundation

public struct HuggingFaceGGUFRepository: Equatable, Identifiable, Sendable {
    public var id: String
    public var author: String?
    public var lastModified: String?
    public var tags: [String]
    public var isGated: Bool?
    public var downloads: Int?
    public var likes: Int?

    public init(
        id: String,
        author: String? = nil,
        lastModified: String? = nil,
        tags: [String] = [],
        isGated: Bool? = nil,
        downloads: Int? = nil,
        likes: Int? = nil
    ) {
        self.id = id
        self.author = author
        self.lastModified = lastModified
        self.tags = tags
        self.isGated = isGated
        self.downloads = downloads
        self.likes = likes
    }
}

public struct HuggingFaceGGUFFile: Equatable, Identifiable, Sendable {
    public var repoID: String
    public var path: String
    public var sizeBytes: Int64?
    public var downloadURL: URL

    public var id: String {
        "\(repoID)/\(path)"
    }

    public var fileName: String {
        URL(fileURLWithPath: path).lastPathComponent
    }

    public init(repoID: String, path: String, sizeBytes: Int64? = nil, downloadURL: URL) {
        self.repoID = repoID
        self.path = path
        self.sizeBytes = sizeBytes
        self.downloadURL = downloadURL
    }
}

public struct GGUFDownloadRequest: Equatable, Sendable {
    public var remoteURL: URL
    public var destinationURL: URL
    public var expectedBytes: Int64?

    public init(remoteURL: URL, destinationURL: URL, expectedBytes: Int64? = nil) {
        self.remoteURL = remoteURL
        self.destinationURL = destinationURL
        self.expectedBytes = expectedBytes
    }
}

public struct GGUFDownloadProgress: Equatable, Sendable {
    public var bytesWritten: Int64
    public var totalBytes: Int64?

    public init(bytesWritten: Int64, totalBytes: Int64? = nil) {
        self.bytesWritten = bytesWritten
        self.totalBytes = totalBytes
    }

    public var fractionCompleted: Double? {
        guard let totalBytes, totalBytes > 0 else {
            return nil
        }

        return min(1, max(0, Double(bytesWritten) / Double(totalBytes)))
    }
}

public enum GGUFAcquisitionError: LocalizedError, Equatable {
    case emptySearchQuery
    case invalidBaseURL
    case invalidRepositoryID(String)
    case invalidGGUFFilePath(String)
    case invalidDownloadDirectory(String)
    case invalidHTTPStatus(Int)
    case invalidResumeRange(expectedStart: Int64, actualStart: Int64?)
    case emptyDownload
    case incompleteDownload(expectedBytes: Int64, actualBytes: Int64)
    case noGGUFFilesFound(String)
    case fileSystem(String)

    public var errorDescription: String? {
        switch self {
        case .emptySearchQuery:
            return "Enter a Hugging Face search query before searching."
        case .invalidBaseURL:
            return "Hugging Face API URL could not be built."
        case .invalidRepositoryID(let repoID):
            return "Repository id is not supported: \(repoID)."
        case .invalidGGUFFilePath(let path):
            return "GGUF file path is not supported: \(path)."
        case .invalidDownloadDirectory(let path):
            return "Download directory is not available: \(path)."
        case .invalidHTTPStatus(let statusCode):
            return "Hugging Face request returned HTTP \(statusCode)."
        case .invalidResumeRange(let expectedStart, let actualStart):
            if let actualStart {
                return "Hugging Face resume response started at byte \(actualStart), expected byte \(expectedStart)."
            }
            return "Hugging Face resume response did not include a usable Content-Range header."
        case .emptyDownload:
            return "Downloaded GGUF response was empty."
        case .incompleteDownload(let expectedBytes, let actualBytes):
            return "Downloaded file size did not match the expected size: expected \(expectedBytes) bytes, got \(actualBytes) bytes."
        case .noGGUFFilesFound(let repoID):
            return "No .gguf files were found in \(repoID)."
        case .fileSystem(let message):
            return message
        }
    }
}

public enum GGUFDownloadDestination {
    public static func destinationURL(
        for file: HuggingFaceGGUFFile,
        in downloadDirectory: URL
    ) throws -> URL {
        let components = file.repoID.split(separator: "/", omittingEmptySubsequences: false)
        guard components.count == 2,
              let owner = sanitizedPathComponent(String(components[0])),
              let repo = sanitizedPathComponent(String(components[1]))
        else {
            throw GGUFAcquisitionError.invalidRepositoryID(file.repoID)
        }
        guard let fileName = sanitizedFileName(fromPath: file.path) else {
            throw GGUFAcquisitionError.invalidGGUFFilePath(file.path)
        }

        return downloadDirectory
            .appendingPathComponent(owner, isDirectory: true)
            .appendingPathComponent(repo, isDirectory: true)
            .appendingPathComponent(fileName, isDirectory: false)
    }

    public static func partialURL(for destinationURL: URL) -> URL {
        destinationURL.deletingLastPathComponent()
            .appendingPathComponent(destinationURL.lastPathComponent + ".part")
    }

    private static func sanitizedPathComponent(_ value: String) -> String? {
        guard isSupportedPathComponent(value) else {
            return nil
        }

        return value.replacingOccurrences(of: ":", with: "-")
    }

    private static func sanitizedFileName(fromPath path: String) -> String? {
        let components = path.split(separator: "/", omittingEmptySubsequences: false)
        guard let lastComponent = components.last,
              components.allSatisfy({ component in
                  isSupportedPathComponent(String(component))
              }),
              let fileName = sanitizedPathComponent(String(lastComponent)),
              fileName.lowercased().hasSuffix(".gguf")
        else {
            return nil
        }

        return fileName
    }

    private static func isSupportedPathComponent(_ value: String) -> Bool {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        return !value.isEmpty
            && value == trimmed
            && value != "."
            && value != ".."
            && !value.contains("/")
            && !value.contains("\\")
    }
}
