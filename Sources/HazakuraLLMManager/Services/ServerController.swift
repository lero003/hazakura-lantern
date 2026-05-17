import Foundation
import HazakuraLLMManagerCore

final class ServerController: ObservableObject {
    @Published private(set) var status: ServerStatus = .stopped
    @Published private(set) var logEntries: [LogEntry] = []
    @Published private(set) var lastErrorMessage: String?
    @Published private(set) var processIdentifier: Int32?
    @Published private(set) var endpointHealthStatus: EndpointHealthStatus = .unchecked
    @Published var configuration: RuntimeConfiguration

    private let adapter: LlamaServerAdapter
    private let endpointHealthChecker: EndpointHealthChecker
    private let configurationStore: ConfigurationStore
    private let fileManager: FileManager
    private var process: Process?
    private var stdoutPipe: Pipe?
    private var stderrPipe: Pipe?
    private var isRestartPending = false
    private var logBuffer = LogBuffer(maxEntries: 2_000)

    init(
        adapter: LlamaServerAdapter = LlamaServerAdapter(),
        endpointHealthChecker: EndpointHealthChecker = EndpointHealthChecker(),
        configurationStore: ConfigurationStore = ConfigurationStore(),
        fileManager: FileManager = .default
    ) {
        self.adapter = adapter
        self.endpointHealthChecker = endpointHealthChecker
        self.configurationStore = configurationStore
        self.fileManager = fileManager
        self.configuration = configurationStore.load()
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

    func updateConfiguration(_ update: (inout RuntimeConfiguration) -> Void) {
        guard process == nil else {
            appendLog("Configuration changes will apply on the next start.", stream: .info)
            var updated = configuration
            update(&updated)
            configuration = updated
            configurationStore.save(updated)
            return
        }

        update(&configuration)
        configurationStore.save(configuration)
        endpointHealthStatus = .unchecked
    }

    func start() {
        guard canStart else {
            return
        }

        var processRunCommand: LaunchCommand?

        do {
            let command = try adapter.buildLaunchCommand(config: configuration)
            try validateStartPreconditions(configuration)

            configurationStore.save(configuration)
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
                LaunchProcessFailureMessage.describe(error, command: $0)
            } ?? error.localizedDescription
            status = .error
            lastErrorMessage = message
            appendLog(message, stream: .error)
        }
    }

    func stop() {
        guard let process else {
            status = .stopped
            processIdentifier = nil
            return
        }

        guard process.isRunning else {
            handleTermination(process)
            return
        }

        status = .stopping
        appendLog("Stopping process pid \(process.processIdentifier).", stream: .info)
        process.terminate()
    }

    func restart() {
        if process?.isRunning == true {
            isRestartPending = true
            appendLog("Restart requested; waiting for the current process to stop.", stream: .info)
            stop()
        } else {
            start()
        }
    }

    func clearLogs() {
        logBuffer.clear()
        logEntries = logBuffer.entries
    }

    func checkEndpointHealth() {
        guard let healthURL = adapter.healthCheckURL(config: configuration) else {
            endpointHealthStatus = .unhealthy(message: "Health check URL is not valid.")
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

    private func validateStartPreconditions(_ configuration: RuntimeConfiguration) throws {
        guard fileManager.isExecutableFile(atPath: configuration.runtimeExecutablePath) else {
            throw LaunchPreflightError.runtimeNotExecutable(configuration.runtimeExecutablePath)
        }

        guard fileManager.fileExists(atPath: configuration.modelPath) else {
            throw LaunchPreflightError.modelFileMissing(configuration.modelPath)
        }
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

        if status == .stopping || exitCode == 0 {
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
