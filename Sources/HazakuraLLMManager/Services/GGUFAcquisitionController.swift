import Foundation
import HazakuraLLMManagerCore

@MainActor
final class GGUFAcquisitionController: ObservableObject {
    enum DownloadState: Equatable {
        case idle
        case running(GGUFDownloadProgress, destination: URL)
        case completed(URL)
        case failed(String)
        case cancelled(URL)
    }

    @Published var searchQuery = ""
    @Published private(set) var repositories: [HuggingFaceGGUFRepository] = []
    @Published private(set) var selectedRepository: HuggingFaceGGUFRepository?
    @Published private(set) var files: [HuggingFaceGGUFFile] = []
    @Published var selectedFile: HuggingFaceGGUFFile?
    @Published var downloadDirectoryPath: String
    @Published private(set) var isSearching = false
    @Published private(set) var isLoadingFiles = false
    @Published private(set) var message: String?
    @Published private(set) var downloadState: DownloadState = .idle

    private let searchClient: any HuggingFaceGGUFSearching
    private let downloader: any GGUFFileDownloading
    private let configurationStore: ConfigurationStore
    private var searchTask: Task<Void, Never>?
    private var filesTask: Task<Void, Never>?
    private var downloadTask: Task<Void, Never>?

    init(
        searchClient: any HuggingFaceGGUFSearching = HuggingFaceGGUFClient(),
        downloader: any GGUFFileDownloading = GGUFFileDownloader(),
        configurationStore: ConfigurationStore = ConfigurationStore()
    ) {
        self.searchClient = searchClient
        self.downloader = downloader
        self.configurationStore = configurationStore
        self.downloadDirectoryPath = configurationStore.loadGGUFDownloadDirectory()
    }

    var canSearch: Bool {
        !isSearching && !searchQuery.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var canLoadFiles: Bool {
        selectedRepository != nil && !isLoadingFiles
    }

    var canDownload: Bool {
        selectedFile != nil &&
            !downloadDirectoryPath.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
            !isDownloading
    }

    var isDownloading: Bool {
        if case .running = downloadState {
            return true
        }
        return false
    }

    var completedURL: URL? {
        if case .completed(let url) = downloadState {
            return url
        }
        return nil
    }

    func chooseDownloadDirectory(_ path: String) {
        downloadDirectoryPath = path
        configurationStore.saveGGUFDownloadDirectory(path)
    }

    func search() {
        guard canSearch else { return }
        searchTask?.cancel()
        repositories = []
        selectedRepository = nil
        files = []
        selectedFile = nil
        message = nil
        isSearching = true
        let query = searchQuery
        let client = searchClient

        searchTask = Task { [weak self] in
            do {
                let results = try await client.searchRepositories(query: query, limit: 20)
                await MainActor.run {
                    guard let self else { return }
                    self.repositories = results
                    self.selectedRepository = results.first
                    self.isSearching = false
                    self.message = results.isEmpty ? self.localized("No GGUF repositories found.") : nil
                    if let selectedRepository = results.first {
                        self.loadFiles(for: selectedRepository)
                    }
                }
            } catch is CancellationError {
                await MainActor.run {
                    self?.isSearching = false
                }
            } catch {
                await MainActor.run {
                    guard let self else { return }
                    self.isSearching = false
                    self.message = error.localizedDescription
                }
            }
        }
    }

    func selectRepository(_ repository: HuggingFaceGGUFRepository) {
        selectedRepository = repository
        selectedFile = nil
        files = []
        loadFiles(for: repository)
    }

    func loadFilesForSelectedRepository() {
        guard let selectedRepository else { return }
        loadFiles(for: selectedRepository)
    }

    func downloadSelectedFile() {
        guard let selectedFile else { return }
        let directoryPath = downloadDirectoryPath.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !directoryPath.isEmpty else {
            message = localized("Choose a download directory first.")
            return
        }

        let destinationURL: URL
        do {
            let directoryURL = try GGUFDownloadDestination.downloadDirectoryURL(fromPath: directoryPath)
            destinationURL = try GGUFDownloadDestination.destinationURL(
                for: selectedFile,
                in: directoryURL
            )
        } catch {
            message = error.localizedDescription
            return
        }
        configurationStore.saveGGUFDownloadDirectory(directoryPath)

        downloadTask?.cancel()
        message = nil
        downloadState = .running(
            GGUFDownloadProgress(bytesWritten: 0, totalBytes: selectedFile.sizeBytes),
            destination: destinationURL
        )
        let downloader = downloader
        let request = GGUFDownloadRequest(
            remoteURL: selectedFile.downloadURL,
            destinationURL: destinationURL,
            expectedBytes: selectedFile.sizeBytes
        )

        downloadTask = Task { [weak self] in
            do {
                let url = try await downloader.download(request) { progress in
                    Task { @MainActor [weak self] in
                        self?.downloadState = .running(progress, destination: destinationURL)
                    }
                }

                await MainActor.run {
                    self?.downloadState = .completed(url)
                    self?.message = self?.localized("Downloaded %@.", url.lastPathComponent)
                }
            } catch is CancellationError {
                await MainActor.run {
                    self?.downloadState = .cancelled(destinationURL)
                    self?.message = self?.localized("Download cancelled. Partial file was kept for resume.")
                }
            } catch {
                await MainActor.run {
                    self?.downloadState = .failed(error.localizedDescription)
                    self?.message = error.localizedDescription
                }
            }
        }
    }

    func cancelDownload() {
        downloadTask?.cancel()
    }

    private func loadFiles(for repository: HuggingFaceGGUFRepository) {
        filesTask?.cancel()
        files = []
        selectedFile = nil
        message = nil
        isLoadingFiles = true
        let client = searchClient

        filesTask = Task { [weak self] in
            do {
                let loadedFiles = try await client.listGGUFFiles(repoID: repository.id)
                await MainActor.run {
                    guard let self else { return }
                    self.files = loadedFiles
                    self.selectedFile = loadedFiles.first
                    self.isLoadingFiles = false
                }
            } catch is CancellationError {
                await MainActor.run {
                    self?.isLoadingFiles = false
                }
            } catch {
                await MainActor.run {
                    guard let self else { return }
                    self.isLoadingFiles = false
                    self.message = error.localizedDescription
                }
            }
        }
    }

    private func localized(_ key: String) -> String {
        String(
            localized: String.LocalizationValue(key),
            bundle: .module,
            locale: selectedAppLocale
        )
    }

    private func localized(_ format: String, _ arguments: CVarArg...) -> String {
        let format = String(
            localized: String.LocalizationValue(format),
            bundle: .module,
            locale: selectedAppLocale
        )
        return String(format: format, locale: selectedAppLocale, arguments: arguments)
    }

    private var selectedAppLocale: Locale {
        let rawValue = UserDefaults.standard.string(forKey: AppLanguage.storageKey)
            ?? AppLanguage.system.rawValue
        return (AppLanguage(rawValue: rawValue) ?? .system).locale
    }
}
