import Foundation
import HazakuraLLMManagerCore

final class ServerController: ObservableObject {
    @Published private(set) var status: ServerStatus = .stopped
    @Published private(set) var logEntries: [LogEntry] = []
    @Published private(set) var lastErrorMessage: String?
    @Published private(set) var activeProfileName: String
    @Published private(set) var profileFileMessage: String?
    @Published private(set) var processIdentifier: Int32?
    @Published private(set) var endpointHealthStatus: EndpointHealthStatus = .unchecked
    @Published private(set) var recentPaths: RecentRuntimePaths
    @Published var configuration: RuntimeConfiguration

    private let adapter: any RuntimeAdapter
    private let endpointHealthChecker: EndpointHealthChecker
    private let configurationStore: ConfigurationStore
    private let fileManager: FileManager
    private var process: Process?
    private var stdoutPipe: Pipe?
    private var stderrPipe: Pipe?
    private var isRestartPending = false
    private var logBuffer = LogBuffer(maxEntries: 2_000)

    init(
        adapter: any RuntimeAdapter = LlamaServerAdapter(),
        endpointHealthChecker: EndpointHealthChecker = EndpointHealthChecker(),
        configurationStore: ConfigurationStore = ConfigurationStore(),
        fileManager: FileManager = .default
    ) {
        self.adapter = adapter
        self.endpointHealthChecker = endpointHealthChecker
        self.configurationStore = configurationStore
        self.fileManager = fileManager
        let activeProfile = configurationStore.loadRuntimeProfile()
        self.configuration = activeProfile.configuration
        self.activeProfileName = activeProfile.name
        self.recentPaths = configurationStore.loadRecentPaths()
    }

    var canStart: Bool {
        status == .stopped || status == .error
    }

    var canStop: Bool {
        status == .starting || status == .running
    }

    var canRestart: Bool {
        status == .running || status == .error
    }

    var launchCommandPreview: String {
        do {
            return try adapter.buildLaunchCommand(config: configuration).displayString
        } catch {
            return error.localizedDescription
        }
    }

    var runtimeProfileDocument: RuntimeProfileDocument {
        RuntimeProfileDocument(name: activeProfileName, configuration: configuration)
    }

    var runtimeEndpoint: RuntimeEndpoint? {
        try? adapter.endpoint(config: configuration)
    }

    var runtimeEndpointErrorMessage: String? {
        do {
            _ = try adapter.endpoint(config: configuration)
            return nil
        } catch {
            return error.localizedDescription
        }
    }

    func updateConfiguration(_ update: (inout RuntimeConfiguration) -> Void) {
        guard process == nil else {
            appendLog("Configuration changes will apply on the next start.", stream: .info)
            var updated = configuration
            update(&updated)
            configuration = updated
            saveActiveProfile(configuration: updated)
            return
        }

        update(&configuration)
        saveActiveProfile(configuration: configuration)
        endpointHealthStatus = .unchecked
    }

    func selectRuntimeExecutablePath(_ path: String) {
        updateConfiguration { configuration in
            configuration.runtimeExecutablePath = path
        }
        recentPaths = configurationStore.recordRuntimeExecutablePath(path)
    }

    func selectModelPath(_ path: String) {
        updateConfiguration { configuration in
            configuration.modelPath = path
        }
        recentPaths = configurationStore.recordModelPath(path)
    }

    func start() {
        guard canStart else {
            return
        }

        endpointHealthStatus = .unchecked
        var processRunCommand: LaunchCommand?

        do {
            let command = try adapter.buildLaunchCommand(config: configuration)
            try adapter.validateLaunchPreconditions(config: configuration, fileManager: fileManager)

            saveActiveProfile(configuration: configuration)
            clearError()
            status = .starting
            appendLog("Launch: \(command.displayString)", stream: .info)

            let process = Process()
            let stdoutPipe = Pipe()
            let stderrPipe = Pipe()

            process.executableURL = URL(fileURLWithPath: command.executablePath)
            process.arguments = command.arguments
            process.standardOutput = stdoutPipe
            process.standardError = stderrPipe

            stdoutPipe.fileHandleForReading.readabilityHandler = { [weak self] handle in
                self?.readAvailableData(from: handle, stream: .stdout)
            }

            stderrPipe.fileHandleForReading.readabilityHandler = { [weak self] handle in
                self?.readAvailableData(from: handle, stream: .stderr)
            }

            process.terminationHandler = { [weak self] process in
                DispatchQueue.main.async {
                    self?.handleTermination(process)
                }
            }

            processRunCommand = command
            try process.run()

            self.process = process
            self.stdoutPipe = stdoutPipe
            self.stderrPipe = stderrPipe
            self.processIdentifier = process.processIdentifier
            self.status = .running
            appendLog("Process started with pid \(process.processIdentifier).", stream: .info)
        } catch {
            let message = processRunCommand.map {
                adapter.describeLaunchProcessFailure(error, command: $0)
            } ?? error.localizedDescription
            status = .error
            lastErrorMessage = message
            appendLog(message, stream: .error)
        }
    }

    func stop() {
        stop(marking: .stopping)
    }

    func restart() {
        if process?.isRunning == true {
            isRestartPending = true
            appendLog("Restart requested; waiting for the current process to stop.", stream: .info)
            stop(marking: .restarting)
        } else {
            start()
        }
    }

    private func stop(marking stoppingStatus: ServerStatus) {
        guard let process else {
            status = .stopped
            processIdentifier = nil
            endpointHealthStatus = .unchecked
            return
        }

        guard process.isRunning else {
            handleTermination(process)
            return
        }

        status = stoppingStatus
        endpointHealthStatus = .unchecked
        appendLog("Stopping process pid \(process.processIdentifier).", stream: .info)
        process.terminate()
    }

    func clearLogs() {
        logBuffer.clear()
        logEntries = logBuffer.entries
    }

    func exportRuntimeProfile(to fileURL: URL) {
        do {
            try runtimeProfileDocument.exportJSONData().write(to: fileURL, options: .atomic)
            profileFileMessage = "Exported \(fileURL.lastPathComponent)."
        } catch {
            profileFileMessage = error.localizedDescription
        }
    }

    func importRuntimeProfile(from fileURL: URL) {
        do {
            let data = try Data(contentsOf: fileURL)
            let profile = try RuntimeProfileDocument.importJSONData(data, fromProfileFileURL: fileURL)

            activeProfileName = profile.name
            configuration = profile.configuration
            configurationStore.saveRuntimeProfile(profile)
            recentPaths = configurationStore.recordRuntimeExecutablePath(profile.configuration.runtimeExecutablePath)
            recentPaths = configurationStore.recordModelPath(profile.configuration.modelPath)
            endpointHealthStatus = .unchecked
            let portabilityWarnings = profile.localPortabilityWarnings()
            if let firstWarning = portabilityWarnings.first {
                if portabilityWarnings.count == 1 {
                    profileFileMessage = "Imported \(profile.name). \(firstWarning.localizedDescription)"
                } else {
                    profileFileMessage = "Imported \(profile.name). \(portabilityWarnings.count) local file warnings. \(firstWarning.localizedDescription)"
                }
            } else {
                profileFileMessage = "Imported \(profile.name)."
            }

            if process != nil {
                appendLog("Imported profile changes will apply on the next start.", stream: .info)
            }
        } catch {
            profileFileMessage = error.localizedDescription
        }
    }

    func checkEndpointHealth() {
        let endpoint: RuntimeEndpoint
        do {
            endpoint = try adapter.endpoint(config: configuration)
        } catch {
            endpointHealthStatus = .unhealthy(message: error.localizedDescription)
            return
        }

        guard let healthURL = endpoint.healthCheckURL else {
            endpointHealthStatus = .unhealthy(message: "Health check URL is not available for this adapter.")
            return
        }

        endpointHealthStatus = .checking
        let checker = endpointHealthChecker

        Task { [weak self] in
            let result = await checker.check(healthURL)
            await self?.updateEndpointHealthStatus(result)
        }
    }

    @MainActor
    private func updateEndpointHealthStatus(_ status: EndpointHealthStatus) {
        endpointHealthStatus = status
    }

    private func saveActiveProfile(configuration: RuntimeConfiguration) {
        configurationStore.saveRuntimeProfile(
            RuntimeProfileDocument(name: activeProfileName, configuration: configuration)
        )
    }

    private func readAvailableData(from handle: FileHandle, stream: LogEntry.Stream) {
        let data = handle.availableData
        guard !data.isEmpty else {
            return
        }

        let text = String(decoding: data, as: UTF8.self)
        DispatchQueue.main.async { [weak self] in
            self?.appendLog(text, stream: stream)
        }
    }

    private func handleTermination(_ terminatedProcess: Process) {
        guard process === terminatedProcess else {
            return
        }

        stdoutPipe?.fileHandleForReading.readabilityHandler = nil
        stderrPipe?.fileHandleForReading.readabilityHandler = nil
        stdoutPipe = nil
        stderrPipe = nil
        process = nil
        processIdentifier = nil

        let exitCode = terminatedProcess.terminationStatus
        appendLog("Process exited with code \(exitCode).", stream: .info)
        endpointHealthStatus = .unchecked

        if status == .stopping || status == .restarting || exitCode == 0 {
            status = .stopped
        } else {
            status = .error
            lastErrorMessage = "Process exited with code \(exitCode)."
        }

        if isRestartPending {
            isRestartPending = false
            start()
        }
    }

    private func appendLog(_ text: String, stream: LogEntry.Stream) {
        logBuffer.append(text, stream: stream)
        logEntries = logBuffer.entries
    }

    private func clearError() {
        lastErrorMessage = nil
    }
}
