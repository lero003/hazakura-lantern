import SwiftUI
import HazakuraLLMManagerCore

struct GGUFAcquisitionView: View {
    @ObservedObject var serverController: ServerController
    @StateObject private var acquisition = GGUFAcquisitionController()

    private let fileColumns = [
        GridItem(.adaptive(minimum: 220, maximum: 320), spacing: 10, alignment: .topLeading)
    ]

    var body: some View {
        GroupBox("GGUF Acquisition") {
            VStack(alignment: .leading, spacing: 16) {
                searchSection
                directorySection
                repositorySection
                fileSection
                downloadSection
            }
            .padding(.vertical, 8)
        }
        .frame(maxWidth: .infinity, alignment: .topLeading)
    }

    private var searchSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Hugging Face Search")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)

            ViewThatFits(in: .horizontal) {
                HStack(spacing: 10) {
                    searchField
                    searchButton
                }

                VStack(alignment: .leading, spacing: 8) {
                    searchField
                    searchButton
                }
            }
        }
    }

    private var searchField: some View {
        TextField("Search public GGUF repositories", text: $acquisition.searchQuery)
            .glassTextFieldStyle()
            .onSubmit {
                acquisition.search()
            }
            .accessibilityLabel(Text("Hugging Face GGUF Search"))
    }

    private var searchButton: some View {
        Button {
            acquisition.search()
        } label: {
            Label(acquisition.isSearching ? "Searching" : "Search", systemImage: "magnifyingglass")
        }
        .buttonStyle(PrimaryButtonStyle())
        .disabled(!acquisition.canSearch)
    }

    private var directorySection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Download Directory")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)

            ViewThatFits(in: .horizontal) {
                HStack(spacing: 10) {
                    directoryField
                    chooseDirectoryButton
                }

                VStack(alignment: .leading, spacing: 8) {
                    directoryField
                    chooseDirectoryButton
                }
            }

            Text("Files are saved as <owner>/<repo>/<file.gguf> inside this directory.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private var directoryField: some View {
        TextField("Choose a local models directory", text: $acquisition.downloadDirectoryPath)
            .glassTextFieldStyle()
            .onSubmit {
                acquisition.chooseDownloadDirectory(acquisition.downloadDirectoryPath)
            }
            .accessibilityLabel(Text("GGUF Download Directory"))
    }

    private var chooseDirectoryButton: some View {
        Button {
            if let path = FilePanel.chooseDirectory() {
                acquisition.chooseDownloadDirectory(path)
            }
        } label: {
            Label("Choose", systemImage: "folder")
        }
        .buttonStyle(SecondaryButtonStyle())
    }

    @ViewBuilder
    private var repositorySection: some View {
        if acquisition.isSearching {
            statusRow("Searching Hugging Face...", systemImage: "hourglass")
        } else if !acquisition.repositories.isEmpty {
            VStack(alignment: .leading, spacing: 8) {
                Text("Repositories")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)

                Picker("Repository", selection: repositorySelection) {
                    ForEach(acquisition.repositories) { repository in
                        Text(repository.id)
                            .tag(Optional(repository.id))
                    }
                }
                .labelsHidden()
                .pickerStyle(.menu)
                .frame(maxWidth: 420, alignment: .leading)

                if let selectedRepository = acquisition.selectedRepository {
                    repositorySummary(selectedRepository)
                }
            }
        }
    }

    private var repositorySelection: Binding<String?> {
        Binding {
            acquisition.selectedRepository?.id
        } set: { id in
            guard let id,
                  let repository = acquisition.repositories.first(where: { $0.id == id })
            else {
                return
            }
            acquisition.selectRepository(repository)
        }
    }

    private func repositorySummary(_ repository: HuggingFaceGGUFRepository) -> some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: 8) {
                metadataChip(repository.author ?? localized("Public repo"))
                if let lastModified = repository.lastModified {
                    metadataChip(lastModified)
                }
                if repository.isGated == true {
                    metadataChip(localized("Gated"))
                }
            }

            VStack(alignment: .leading, spacing: 6) {
                metadataChip(repository.author ?? localized("Public repo"))
                if let lastModified = repository.lastModified {
                    metadataChip(lastModified)
                }
                if repository.isGated == true {
                    metadataChip(localized("Gated"))
                }
            }
        }
    }

    @ViewBuilder
    private var fileSection: some View {
        if acquisition.isLoadingFiles {
            statusRow("Loading repository files...", systemImage: "hourglass")
        } else if !acquisition.files.isEmpty {
            VStack(alignment: .leading, spacing: 8) {
                Text("GGUF Files")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)

                LazyVGrid(columns: fileColumns, alignment: .leading, spacing: 10) {
                    ForEach(acquisition.files) { file in
                        fileButton(file)
                    }
                }
            }
        }
    }

    private func fileButton(_ file: HuggingFaceGGUFFile) -> some View {
        Button {
            acquisition.selectedFile = file
        } label: {
            VStack(alignment: .leading, spacing: 6) {
                Label(file.fileName, systemImage: file == acquisition.selectedFile ? "checkmark.circle.fill" : "doc")
                    .font(.callout.weight(.medium))
                    .lineLimit(2)

                Text(file.path)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .truncationMode(.middle)

                if let sizeBytes = file.sizeBytes {
                    Text(ByteCountFormatter.string(fromByteCount: sizeBytes, countStyle: .file))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(10)
            .frame(maxWidth: .infinity, minHeight: 86, alignment: .topLeading)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(file == acquisition.selectedFile ? Color.accentColor.opacity(0.18) : .white.opacity(0.04))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(file == acquisition.selectedFile ? Color.accentColor.opacity(0.45) : .white.opacity(0.08), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    private var downloadSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            ViewThatFits(in: .horizontal) {
                HStack(spacing: 10) {
                    downloadButton
                    cancelButton
                    useModelButton
                    Spacer()
                }

                VStack(alignment: .leading, spacing: 8) {
                    downloadButton
                    HStack(spacing: 10) {
                        cancelButton
                        useModelButton
                    }
                }
            }

            downloadStatus

            if let message = acquisition.message {
                Label {
                    Text(verbatim: message)
                } icon: {
                    Image(systemName: messageSystemImage)
                }
                    .font(.caption)
                    .foregroundStyle(messageForegroundStyle)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private var downloadButton: some View {
        Button {
            acquisition.downloadSelectedFile()
        } label: {
            Label("Download GGUF", systemImage: "arrow.down.circle")
        }
        .buttonStyle(PrimaryButtonStyle())
        .disabled(!acquisition.canDownload)
    }

    private var cancelButton: some View {
        Button {
            acquisition.cancelDownload()
        } label: {
            Label("Cancel", systemImage: "xmark.circle")
        }
        .buttonStyle(SecondaryButtonStyle())
        .disabled(!acquisition.isDownloading)
    }

    private var useModelButton: some View {
        Button {
            if let completedURL = acquisition.completedURL {
                serverController.selectModelPath(completedURL.path)
            }
        } label: {
            Label("Use as Model", systemImage: "checkmark.circle")
        }
        .buttonStyle(SecondaryButtonStyle())
        .disabled(acquisition.completedURL == nil)
    }

    @ViewBuilder
    private var downloadStatus: some View {
        switch acquisition.downloadState {
        case .idle:
            statusRow("Select a public GGUF file, then download it into your local models directory.", systemImage: "info.circle")
        case .running(let progress, let destination):
            VStack(alignment: .leading, spacing: 6) {
                if let fractionCompleted = progress.fractionCompleted {
                    ProgressView(value: fractionCompleted)
                        .progressViewStyle(.linear)
                        .tint(Color.accentColor)
                } else {
                    ProgressView()
                        .progressViewStyle(.linear)
                        .tint(Color.accentColor)
                }

                Text(downloadProgressText(progress, destination: destination))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
        case .completed(let url):
            verbatimStatusRow(localized("Completed: %@", url.path), systemImage: "checkmark.circle")
        case .failed(let message):
            verbatimStatusRow(message, systemImage: "exclamationmark.triangle")
        case .cancelled(let url):
            verbatimStatusRow(
                localized("Cancelled. Resume will use the partial file near %@.", url.lastPathComponent),
                systemImage: "pause.circle"
            )
        }
    }

    private var messageSystemImage: String {
        if case .failed = acquisition.downloadState {
            return "exclamationmark.triangle"
        }
        return "info.circle"
    }

    private var messageForegroundStyle: some ShapeStyle {
        if case .failed = acquisition.downloadState {
            return AnyShapeStyle(.red)
        }
        return AnyShapeStyle(.secondary)
    }

    private func downloadProgressText(_ progress: GGUFDownloadProgress, destination: URL) -> String {
        let written = ByteCountFormatter.string(fromByteCount: progress.bytesWritten, countStyle: .file)
        if let totalBytes = progress.totalBytes {
            let total = ByteCountFormatter.string(fromByteCount: totalBytes, countStyle: .file)
            return localized("%@ of %@ -> %@", written, total, destination.path)
        }

        return localized("%@ -> %@", written, destination.path)
    }

    private func statusRow(_ key: LocalizedStringKey, systemImage: String) -> some View {
        Label {
            Text(key)
        } icon: {
            Image(systemName: systemImage)
        }
        .font(.caption)
        .foregroundStyle(.secondary)
        .fixedSize(horizontal: false, vertical: true)
    }

    private func verbatimStatusRow(_ text: String, systemImage: String) -> some View {
        Label {
            Text(verbatim: text)
        } icon: {
            Image(systemName: systemImage)
        }
        .font(.caption)
        .foregroundStyle(.secondary)
        .fixedSize(horizontal: false, vertical: true)
    }

    private func metadataChip(_ text: String) -> some View {
        Text(text)
            .font(.caption)
            .foregroundStyle(.secondary)
            .lineLimit(1)
            .truncationMode(.middle)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(.black.opacity(0.16), in: Capsule())
    }

    private func localized(_ key: String) -> String {
        NSLocalizedString(key, comment: "")
    }

    private func localized(_ format: String, _ arguments: CVarArg...) -> String {
        String(format: NSLocalizedString(format, comment: ""), arguments: arguments)
    }
}
