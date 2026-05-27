import Foundation

public protocol GGUFFileDownloading: Sendable {
    func download(
        _ request: GGUFDownloadRequest,
        progress: @escaping (GGUFDownloadProgress) -> Void
    ) async throws -> URL
}

public struct GGUFFileDownloader: GGUFFileDownloading, @unchecked Sendable {
    private let session: URLSession
    private let fileManager: FileManager
    private let bufferLimit = 64 * 1_024

    public init(
        session: URLSession = .shared,
        fileManager: FileManager = .default
    ) {
        self.session = session
        self.fileManager = fileManager
    }

    public func download(
        _ request: GGUFDownloadRequest,
        progress: @escaping (GGUFDownloadProgress) -> Void
    ) async throws -> URL {
        let destinationDirectory = request.destinationURL.deletingLastPathComponent()
        try fileManager.createDirectory(
            at: destinationDirectory,
            withIntermediateDirectories: true
        )

        let partialURL = GGUFDownloadDestination.partialURL(for: request.destinationURL)
        if let expectedBytes = request.expectedBytes,
           existingFileSize(at: request.destinationURL) == expectedBytes {
            try? fileManager.removeItem(at: partialURL)
            progress(GGUFDownloadProgress(bytesWritten: expectedBytes, totalBytes: expectedBytes))
            return request.destinationURL
        }

        var partialBytes = existingFileSize(at: partialURL) ?? 0
        if let expectedBytes = request.expectedBytes,
           partialBytes == expectedBytes,
           partialBytes > 0 {
            if fileManager.fileExists(atPath: request.destinationURL.path) {
                try fileManager.removeItem(at: request.destinationURL)
            }
            try fileManager.moveItem(at: partialURL, to: request.destinationURL)
            progress(GGUFDownloadProgress(bytesWritten: expectedBytes, totalBytes: expectedBytes))
            return request.destinationURL
        }
        if let expectedBytes = request.expectedBytes,
           partialBytes > expectedBytes {
            try fileManager.removeItem(at: partialURL)
            partialBytes = 0
        }

        var urlRequest = URLRequest(url: request.remoteURL)
        if partialBytes > 0 {
            urlRequest.setValue("bytes=\(partialBytes)-", forHTTPHeaderField: "Range")
        }

        let (bytes, response) = try await session.bytes(for: urlRequest)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw GGUFAcquisitionError.invalidHTTPStatus(-1)
        }
        let contentRange = Self.contentRange(from: httpResponse.value(forHTTPHeaderField: "Content-Range"))

        switch httpResponse.statusCode {
        case 200:
            partialBytes = 0
            if fileManager.fileExists(atPath: partialURL.path) {
                try fileManager.removeItem(at: partialURL)
            }
            _ = fileManager.createFile(atPath: partialURL.path, contents: Data())
        case 206:
            let resumeStart = contentRange?.start
            guard resumeStart == partialBytes else {
                throw GGUFAcquisitionError.invalidResumeRange(
                    expectedStart: partialBytes,
                    actualStart: resumeStart
                )
            }
            if !fileManager.fileExists(atPath: partialURL.path) {
                _ = fileManager.createFile(atPath: partialURL.path, contents: Data())
            }
        case 416:
            if partialBytes > 0,
               Self.unsatisfiedRangeTotal(from: httpResponse.value(forHTTPHeaderField: "Content-Range")) == partialBytes {
                if let expectedBytes = request.expectedBytes,
                   expectedBytes != partialBytes {
                    throw GGUFAcquisitionError.incompleteDownload(
                        expectedBytes: expectedBytes,
                        actualBytes: partialBytes
                    )
                }
                if fileManager.fileExists(atPath: request.destinationURL.path) {
                    try fileManager.removeItem(at: request.destinationURL)
                }
                try fileManager.moveItem(at: partialURL, to: request.destinationURL)
                progress(GGUFDownloadProgress(bytesWritten: partialBytes, totalBytes: partialBytes))
                return request.destinationURL
            }
            throw GGUFAcquisitionError.invalidHTTPStatus(httpResponse.statusCode)
        default:
            throw GGUFAcquisitionError.invalidHTTPStatus(httpResponse.statusCode)
        }

        if !fileManager.fileExists(atPath: partialURL.path) {
            _ = fileManager.createFile(atPath: partialURL.path, contents: Data())
        }

        let totalBytes = totalBytes(
            httpResponse: httpResponse,
            partialBytes: partialBytes,
            expectedBytes: request.expectedBytes
        )
        var writtenBytes = partialBytes
        progress(GGUFDownloadProgress(bytesWritten: writtenBytes, totalBytes: totalBytes))

        let handle = try FileHandle(forWritingTo: partialURL)
        defer {
            try? handle.close()
        }
        try handle.seekToEnd()

        var buffer = Data()
        buffer.reserveCapacity(bufferLimit)

        do {
            for try await byte in bytes {
                try Task.checkCancellation()
                buffer.append(byte)

                if buffer.count >= bufferLimit {
                    try handle.write(contentsOf: buffer)
                    writtenBytes += Int64(buffer.count)
                    buffer.removeAll(keepingCapacity: true)
                    progress(GGUFDownloadProgress(bytesWritten: writtenBytes, totalBytes: totalBytes))
                }
            }

            if !buffer.isEmpty {
                try handle.write(contentsOf: buffer)
                writtenBytes += Int64(buffer.count)
                progress(GGUFDownloadProgress(bytesWritten: writtenBytes, totalBytes: totalBytes))
            }

            try handle.close()

            if httpResponse.statusCode == 206,
               let responseEnd = contentRange?.end,
               writtenBytes != responseEnd + 1 {
                throw GGUFAcquisitionError.incompleteDownload(
                    expectedBytes: responseEnd + 1,
                    actualBytes: writtenBytes
                )
            }

            if let expectedBytes = completionExpectedBytes(
                httpResponse: httpResponse,
                fallbackExpectedBytes: request.expectedBytes
            ),
               writtenBytes != expectedBytes {
                throw GGUFAcquisitionError.incompleteDownload(
                    expectedBytes: expectedBytes,
                    actualBytes: writtenBytes
                )
            }

            if writtenBytes == 0 {
                try? fileManager.removeItem(at: partialURL)
                throw GGUFAcquisitionError.emptyDownload
            }

            if fileManager.fileExists(atPath: request.destinationURL.path) {
                try fileManager.removeItem(at: request.destinationURL)
            }
            try fileManager.moveItem(at: partialURL, to: request.destinationURL)
            progress(GGUFDownloadProgress(bytesWritten: writtenBytes, totalBytes: totalBytes ?? writtenBytes))
            return request.destinationURL
        } catch is CancellationError {
            throw CancellationError()
        } catch let error as GGUFAcquisitionError {
            throw error
        } catch {
            throw GGUFAcquisitionError.fileSystem(error.localizedDescription)
        }
    }

    private func existingFileSize(at url: URL) -> Int64? {
        guard let attributes = try? fileManager.attributesOfItem(atPath: url.path),
              let size = attributes[.size] as? NSNumber
        else {
            return nil
        }

        return size.int64Value
    }

    private func totalBytes(
        httpResponse: HTTPURLResponse,
        partialBytes: Int64,
        expectedBytes: Int64?
    ) -> Int64? {
        if let expectedBytes {
            return expectedBytes
        }

        if let contentRange = Self.contentRange(from: httpResponse.value(forHTTPHeaderField: "Content-Range")),
           let total = contentRange.totalBytes {
            return total
        }

        if let contentLength = httpResponse.value(forHTTPHeaderField: "Content-Length"),
           let length = Int64(contentLength) {
            return partialBytes + length
        }

        return nil
    }

    private func completionExpectedBytes(
        httpResponse: HTTPURLResponse,
        fallbackExpectedBytes: Int64?
    ) -> Int64? {
        if let fallbackExpectedBytes {
            return fallbackExpectedBytes
        }

        guard httpResponse.statusCode == 206,
              let contentRange = Self.contentRange(from: httpResponse.value(forHTTPHeaderField: "Content-Range"))
        else {
            return nil
        }

        return contentRange.totalBytes
    }

    static func totalBytes(fromContentRange contentRange: String) -> Int64? {
        Self.contentRange(from: contentRange)?.totalBytes
    }

    static func resumeStart(fromContentRange contentRange: String?) -> Int64? {
        Self.contentRange(from: contentRange)?.start
    }

    private static func unsatisfiedRangeTotal(from contentRange: String?) -> Int64? {
        guard let contentRange else {
            return nil
        }

        let trimmed = contentRange.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.lowercased().hasPrefix("bytes */") else {
            return nil
        }

        let total = trimmed[trimmed.index(trimmed.startIndex, offsetBy: 8)...]
        guard let totalBytes = Int64(total), totalBytes > 0 else {
            return nil
        }

        return totalBytes
    }

    private static func contentRange(from contentRange: String?) -> ContentRange? {
        guard let contentRange else {
            return nil
        }

        let trimmed = contentRange.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.lowercased().hasPrefix("bytes "),
              let dashIndex = trimmed.firstIndex(of: "-"),
              let slashIndex = trimmed.lastIndex(of: "/"),
              dashIndex < slashIndex
        else {
            return nil
        }

        let start = trimmed[trimmed.index(trimmed.startIndex, offsetBy: 6)..<dashIndex]
        let end = trimmed[trimmed.index(after: dashIndex)..<slashIndex]
        let total = trimmed[trimmed.index(after: slashIndex)...]
        guard let startBytes = Int64(start),
              let endBytes = Int64(end),
              endBytes >= startBytes
        else {
            return nil
        }

        let totalBytes: Int64?
        if total == "*" {
            totalBytes = nil
        } else if let parsedTotal = Int64(total), parsedTotal > endBytes {
            totalBytes = parsedTotal
        } else {
            return nil
        }

        return ContentRange(start: startBytes, end: endBytes, totalBytes: totalBytes)
    }

    private struct ContentRange {
        var start: Int64
        var end: Int64
        var totalBytes: Int64?
    }
}
