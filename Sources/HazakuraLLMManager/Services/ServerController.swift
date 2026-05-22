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
    @Published private(set) var runtimeCapabilityProbeResult: LlamaServerCapabilityProbeResult?
    @Published private(set) var runtimeCapabilityProbeMessage: String?
    @Published private(set) var isRuntimeCapabilityProbeRunning = false
    @Published var runtimeUpdateCheckTarget: RuntimeUpdateCheckTarget = .llamaCpp
    @Published private(set) var runtimeUpdateAvailability: RuntimeUpdateAvailability?
    @Published private(set) var runtimeUpdateAvailabilityMessage: RuntimeUpdateAvailabilityMessage?
    @Published private(set) var isRuntimeUpdateCheckRunning = false
    @Published private(set) var recentPaths: RecentRuntimePaths
    @Published private(set) var detectedRuntimeExecutablePaths: [String]
    @Published private(set) var loadingElapsedSeconds: Int?
    @Published var configuration: RuntimeConfiguration

    private let adapter: any RuntimeAdapter
    private let endpointHealthChecker: any EndpointHealthChecking
    private let runtimeCapabilityProbe: any LlamaServerCapabilityProbing
    private let runtimeUpdateAvailabilityChecker: any RuntimeUpdateAvailabilityChecking
    private let portAvailabilityChecker: any PortAvailabilityChecking
    private let configurationStore: ConfigurationStore
    private let runtimeDiscovery: LlamaServerRuntimeDiscovery
    private let fileManager: FileManager
    private var process: Process?
    private var stdoutPipe: Pipe?
    private var stderrPipe: Pipe?
    private var isRestartPending = false
    private var logBuffer = LogBuffer(maxEntries: 2_000)
    private var loadingStartedAt: Date?
    private var loadingTimer: Timer?

    init(
        adapter: any RuntimeAdapter = LlamaServerAdapter(),
        endpointHealthChecker: any EndpointHealthChecking = EndpointHealthChecker(),
        runtimeCapabilityProbe: any LlamaServerCapabilityProbing = LlamaServerCapabilityProbe(),
        runtimeUpdateAvailabilityChecker: any RuntimeUpdateAvailabilityChecking = RuntimeUpdateAvailabilityChecker(),
        portAvailabilityChecker: any PortAvailabilityChecking = PortAvailabilityChecker(),
        configurationStore: ConfigurationStore = ConfigurationStore(),
        runtimeDiscovery: LlamaServerRuntimeDiscovery = LlamaServerRuntimeDiscovery(),
        fileManager: FileManager = .default
    ) {
        self.adapter = adapter
        self.endpointHealthChecker = endpointHealthChecker
        self.runtimeCapabilityProbe = runtimeCapabilityProbe
        self.runtimeUpdateAvailabilityChecker = runtimeUpdateAvailabilityChecker
        self.portAvailabilityChecker = portAvailabilityChecker
        self.configurationStore = configurationStore
        self.runtimeDiscovery = runtimeDiscovery
        self.fileManager = fileManager
        let activeProfile = configurationStore.loadRuntimeProfile()
        self.configuration = activeProfile.configuration
        self.activeProfileName = activeProfile.name
        self.recentPaths = configurationStore.loadRecentPaths()
        self.detectedRuntimeExecutablePaths = runtimeDiscovery.installedExecutablePaths(fileManager: fileManager)
    }

    var canStart: Bool {
        status == .stopped || status == .error
    }

    var canStop: Bool {
        status == .starting || status == .loading || status == .running
    }

    var canRestart: Bool {
        status == .running || status == .error
    }

    var canCheckEndpointHealth: Bool {
        status == .running && endpointHealthStatus != .checking
    }

    var launchCommandPreview: String {
        do {
            return try adapter.buildLaunchCommand(config: configuration).displayString
        } catch {
            return error.localizedDescription
        }
    }

    var launchSetupHint: String? {
        adapter.launchSetupHint(config: configuration)
    }

    var launchPreflightHint: String? {
        if let launchSetupHint {
            return launchSetupHint
        }

        guard canStart else {
            return nil
        }

        do {
            try validateLaunchPreflight()
            return nil
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

    var runtimeInstallSourceAdvice: LlamaServerInstallSourceAdvice? {
        LlamaServerInstallSourceAdvice.classify(executablePath: configuration.runtimeExecutablePath)
    }

    var runtimeUpdateReadinessAdvice: LlamaServerUpdateReadinessAdvice? {
        LlamaServerUpdateReadinessAdvice.evaluate(
            executablePath: configuration.runtimeExecutablePath,
            capabilityResult: runtimeCapabilityProbeResult
        )
    }

    func updateConfiguration(_ update: (inout RuntimeConfiguration) -> Void) {
        guard process == nil else {
            appendLog("Configuration changes will apply on the next start.", stream: .info)
            var updated = configuration
            let previousRuntimeExecutablePath = updated.runtimeExecutablePath
            update(&updated)
            configuration = updated
            if updated.runtimeExecutablePath != previousRuntimeExecutablePath {
                clearRuntimeCapabilityProbe()
            }
            saveActiveProfile(configuration: updated)
            return
        }

        let previousRuntimeExecutablePath = configuration.runtimeExecutablePath
        update(&configuration)
        if configuration.runtimeExecutablePath != previousRuntimeExecutablePath {
            clearRuntimeCapabilityProbe()
        }
        saveActiveProfile(configuration: configuration)
        endpointHealthStatus = .unchecked
    }

    func selectRuntimeExecutablePath(_ path: String) {
        updateConfiguration { configuration in
            configuration.runtimeExecutablePath = path
        }
        recentPaths = configurationStore.recordRuntimeExecutablePath(path)
    }

    func refreshDetectedRuntimeExecutablePaths() {
        detectedRuntimeExecutablePaths = runtimeDiscovery.installedExecutablePaths(fileManager: fileManager)
    }

    func selectModelPath(_ path: String) {
        updateConfiguration { configuration in
            configuration.modelPath = path
        }
        recentPaths = configurationStore.recordModelPath(path)
    }

    func applyPreset(_ preset: LlamaServerPreset) {
        updateConfiguration { configuration in
            configuration = preset.applying(to: configuration)
        }
    }

    func checkRuntimeCapabilities() {
        let executablePath = configuration.runtimeExecutablePath.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !executablePath.isEmpty else {
            runtimeCapabilityProbeResult = nil
            runtimeCapabilityProbeMessage = "Choose a llama-server executable before checking runtime options."
            return
        }

        guard !isRuntimeCapabilityProbeRunning else {
            return
        }

        isRuntimeCapabilityProbeRunning = true
        runtimeCapabilityProbeMessage = nil
        let probe = runtimeCapabilityProbe

        DispatchQueue.global(qos: .utility).async {
            let result = probe.probe(executablePath: executablePath)

            DispatchQueue.main.async { [weak self] in
                guard let self else {
                    return
                }

                self.isRuntimeCapabilityProbeRunning = false
                guard self.configuration.runtimeExecutablePath.trimmingCharacters(in: .whitespacesAndNewlines) == executablePath else {
                    self.runtimeCapabilityProbeMessage = "Runtime selection changed; check capabilities again."
                    return
                }

                self.runtimeCapabilityProbeResult = result
                self.runtimeCapabilityProbeMessage = result.capabilities.versionSummary.map {
                    "Runtime: \($0)"
                } ?? "Runtime version unavailable."
                self.runtimeUpdateAvailability = nil
                self.runtimeUpdateAvailabilityMessage = nil
            }
        }
    }

    func checkRuntimeUpdates() {
        guard !isRuntimeUpdateCheckRunning else {
            return
        }

        isRuntimeUpdateCheckRunning = true
        runtimeUpdateAvailability = nil
        runtimeUpdateAvailabilityMessage = nil

        let target = runtimeUpdateCheckTarget
        let localVersionSummary = runtimeCapabilityProbeResult?.capabilities.versionSummary
        let checker = runtimeUpdateAvailabilityChecker

        Task { [weak self] in
            do {
                let availability = try await checker.check(
                    target: target,
                    localVersionSummary: localVersionSummary
                )
                await MainActor.run { [weak self] in
                    guard let self else {
                        return
                    }

                    self.isRuntimeUpdateCheckRunning = false
                    guard self.runtimeUpdateCheckTarget == target else {
                        self.runtimeUpdateAvailabilityMessage = .targetChanged
                        return
                    }

                    self.runtimeUpdateAvailability = availability
                }
            } catch {
                await MainActor.run { [weak self] in
                    guard let self else {
                        return
                    }

                    self.isRuntimeUpdateCheckRunning = false
                    self.runtimeUpdateAvailabilityMessage = .failed(error.localizedDescription)
                }
            }
        }
    }

    func start() {
        guard canStart else {
            return
        }

        endpointHealthStatus = .unchecked
        var processRunCommand: LaunchCommand?

        do {
            let command = try adapter.buildLaunchCommand(config: configuration)
            try validateLaunchPreflight()

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
            self.status = .loading
            beginLoadingTimer()
            appendLog("Process started with pid \(process.processIdentifier); waiting for runtime readiness.", stream: .info)
        } catch {
            endLoadingTimer()
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
            clearRuntimeCapabilityProbe()
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
        guard status == .running else {
            endpointHealthStatus = .unchecked
            return
        }

        let endpoint: RuntimeEndpoint
        do {
            endpoint = try adapter.endpoint(config: configuration)
        } catch {
            endpointHealthStatus = .unhealthy(message: error.localizedDescription)
            return
        }

        guard let healthRequest = endpoint.endpointHealthRequest else {
            endpointHealthStatus = .unhealthy(message: "Health check URL is not available for this adapter.")
            return
        }

        endpointHealthStatus = .checking
        let checker = endpointHealthChecker

        Task { [weak self] in
            let result = await checker.check(healthRequest)
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
            guard let self else {
                return
            }

            self.appendLog(text, stream: stream)
            self.markRunningIfRuntimeReady(from: text)
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
        endLoadingTimer()

        let exitCode = terminatedProcess.terminationStatus
        let requestedAction: ProcessTerminationRequest? = switch status {
        case .stopping:
            .stop
        case .restarting:
            .restart
        default:
            nil
        }
        let terminationMessage = ProcessTerminationMessage.describe(
            status: exitCode,
            reason: terminatedProcess.terminationReason,
            requestedAction: requestedAction
        )
        appendLog(terminationMessage, stream: .info)
        endpointHealthStatus = .unchecked

        if status == .stopping || status == .restarting || exitCode == 0 {
            status = .stopped
        } else {
            status = .error
            lastErrorMessage = terminationMessage
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

    private func markRunningIfRuntimeReady(from text: String) {
        guard status == .loading else {
            return
        }

        guard LlamaServerReadinessLogDetector.isReadyLog(text) else {
            return
        }

        status = .running
        endLoadingTimer()
        appendLog("Runtime is ready for local client connections.", stream: .info)
    }

    private func validateLaunchPreflight() throws {
        try adapter.validateLaunchPreconditions(config: configuration, fileManager: fileManager)

        guard portAvailabilityChecker.isPortAvailable(configuration.port) else {
            throw LaunchPreflightError.portUnavailable(configuration.port)
        }
    }

    private func beginLoadingTimer() {
        loadingTimer?.invalidate()
        loadingStartedAt = Date()
        loadingElapsedSeconds = 0
        loadingTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            self?.updateLoadingElapsedSeconds()
        }
    }

    private func updateLoadingElapsedSeconds() {
        guard let loadingStartedAt else {
            loadingElapsedSeconds = nil
            return
        }

        loadingElapsedSeconds = max(0, Int(Date().timeIntervalSince(loadingStartedAt)))
    }

    private func endLoadingTimer() {
        loadingTimer?.invalidate()
        loadingTimer = nil
        loadingStartedAt = nil
        loadingElapsedSeconds = nil
    }

    private func clearError() {
        lastErrorMessage = nil
    }

    private func clearRuntimeCapabilityProbe() {
        runtimeCapabilityProbeResult = nil
        runtimeCapabilityProbeMessage = nil
        runtimeUpdateAvailability = nil
        runtimeUpdateAvailabilityMessage = nil
    }
}

enum RuntimeUpdateAvailabilityMessage: Equatable {
    case targetChanged
    case failed(String)
}
