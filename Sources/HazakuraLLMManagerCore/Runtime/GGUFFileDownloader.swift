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

        if let expectedBytes = request.expectedBytes,
           existingFileSize(at: request.destinationURL) == expectedBytes {
            progress(GGUFDownloadProgress(bytesWritten: expectedBytes, totalBytes: expectedBytes))
            return request.destinationURL
        }

        let partialURL = GGUFDownloadDestination.partialURL(for: request.destinationURL)
        var partialBytes = existingFileSize(at: partialURL) ?? 0
        var urlRequest = URLRequest(url: request.remoteURL)
        if partialBytes > 0 {
            urlRequest.setValue("bytes=\(partialBytes)-", forHTTPHeaderField: "Range")
        }

        let (bytes, response) = try await session.bytes(for: urlRequest)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw GGUFAcquisitionError.invalidHTTPStatus(-1)
        }

        switch httpResponse.statusCode {
        case 200:
            partialBytes = 0
            if fileManager.fileExists(atPath: partialURL.path) {
                try fileManager.removeItem(at: partialURL)
            }
            _ = fileManager.createFile(atPath: partialURL.path, contents: Data())
        case 206:
            if !fileManager.fileExists(atPath: partialURL.path) {
                _ = fileManager.createFile(atPath: partialURL.path, contents: Data())
            }
        case 416:
            try? fileManager.removeItem(at: partialURL)
            throw GGUFAcquisitionError.invalidHTTPStatus(httpResponse.statusCode)
        default:
            guard (200...299).contains(httpResponse.statusCode) else {
                throw GGUFAcquisitionError.invalidHTTPStatus(httpResponse.statusCode)
            }
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

            if fileManager.fileExists(atPath: request.destinationURL.path) {
                try fileManager.removeItem(at: request.destinationURL)
            }
            try fileManager.moveItem(at: partialURL, to: request.destinationURL)
            progress(GGUFDownloadProgress(bytesWritten: writtenBytes, totalBytes: totalBytes ?? writtenBytes))
            return request.destinationURL
        } catch is CancellationError {
            throw CancellationError()
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

        if let contentRange = httpResponse.value(forHTTPHeaderField: "Content-Range"),
           let total = Self.totalBytes(fromContentRange: contentRange) {
            return total
        }

        if let contentLength = httpResponse.value(forHTTPHeaderField: "Content-Length"),
           let length = Int64(contentLength) {
            return partialBytes + length
        }

        return nil
    }

    static func totalBytes(fromContentRange contentRange: String) -> Int64? {
        guard let slashIndex = contentRange.lastIndex(of: "/") else {
            return nil
        }

        let total = contentRange[contentRange.index(after: slashIndex)...]
        return Int64(total)
    }
}
