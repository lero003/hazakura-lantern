import SwiftUI
import HazakuraLLMManagerCore

struct SmokeConsoleView: View {
    @ObservedObject var controller: ServerController

    @State private var prompt = ClientSmokeRequest.defaultUserText
    @State private var responseText: String?
    @State private var resultMetrics: ClientSmokeResult?
    @State private var failureMetrics: SmokeFailureMetrics?
    @State private var errorMessage: String?
    @State private var isRunning = false
    @State private var didCopy = false
    @State private var copyGeneration = 0

    var body: some View {
        GroupBox("Smoke Console") {
            VStack(alignment: .leading, spacing: 14) {
                endpointSummary
                promptEditor

                ViewThatFits(in: .horizontal) {
                    HStack(spacing: 10) {
                        smokeActions
                        Spacer()
                        statusMessage
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        smokeActions
                        statusMessage
                    }
                }

                responsePanel
            }
            .padding(.vertical, 8)
        }
        .frame(maxWidth: .infinity, alignment: .topLeading)
    }

    @ViewBuilder
    private var endpointSummary: some View {
        if let endpoint = controller.runtimeEndpoint {
            VStack(alignment: .leading, spacing: 6) {
                Text("Local Endpoint")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)

                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Text(endpoint.apiBaseURLString)
                        .font(.system(.body, design: .monospaced))
                        .textSelection(.enabled)
                        .lineLimit(1)
                        .truncationMode(.middle)

                    Text(endpoint.modelID)
                        .font(.system(.caption, design: .monospaced))
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(.black.opacity(0.18), in: Capsule())
                }
            }
        } else {
            Label(
                controller.runtimeEndpointErrorMessage ?? "Endpoint is not available for the current configuration.",
                systemImage: "exclamationmark.triangle"
            )
            .font(.caption)
            .foregroundStyle(.secondary)
        }
    }

    private var promptEditor: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Smoke Prompt")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)

            TextEditor(text: $prompt)
                .font(.body)
                .frame(minHeight: 52, idealHeight: 60, maxHeight: 70)
                .scrollContentBackground(.hidden)
                .padding(8)
                .background(.black.opacity(0.16), in: RoundedRectangle(cornerRadius: 6))
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(Color.white.opacity(0.08), lineWidth: 1)
                )
                .accessibilityLabel(Text("Smoke Prompt"))
                .overlay(alignment: .topLeading) {
                    if prompt.isEmpty {
                        Text("Enter a short smoke prompt.")
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 16)
                            .allowsHitTesting(false)
                    }
                }
        }
    }

    private var smokeActions: some View {
        HStack(spacing: 10) {
            Button {
                runSmoke()
            } label: {
                Label {
                    Text(LocalizedStringKey(isRunning ? "Running Smoke" : "Run Smoke"))
                } icon: {
                    Image(systemName: "paperplane")
                }
            }
            .buttonStyle(PrimaryButtonStyle())
            .disabled(!canRunSmoke)
            .accessibilityHint(Text("Send the prompt to the selected local endpoint without saving a conversation."))

            Button {
                copyResult()
            } label: {
                Label("Copy Result", systemImage: didCopy ? "checkmark.circle" : "doc.on.doc")
            }
            .buttonStyle(SecondaryButtonStyle())
            .disabled(copyableResult == nil)
            .accessibilityHint(Text("Copy the latest smoke response or error with visible metrics."))

            Button {
                clearResult()
            } label: {
                Label("Clear Result", systemImage: "xmark.circle")
            }
            .buttonStyle(SecondaryButtonStyle())
            .disabled(responseText == nil && errorMessage == nil)
            .accessibilityHint(Text("Clear the displayed smoke response, error, and metrics."))
        }
    }

    @ViewBuilder
    private var statusMessage: some View {
        if isRunning {
            Label("Running local endpoint smoke...", systemImage: "hourglass")
                .font(.caption)
                .foregroundStyle(.secondary)
        } else if didCopy {
            Label("Copied!", systemImage: "checkmark.circle")
                .font(.caption)
                .foregroundStyle(.green)
        } else if !isServerRunning {
            Label("Start the server before running Smoke Console.", systemImage: "info.circle")
                .font(.caption)
                .foregroundStyle(.secondary)
        } else if isPromptEmpty {
            Label("Enter a smoke prompt before running.", systemImage: "text.cursor")
                .font(.caption)
                .foregroundStyle(.secondary)
        } else if controller.runtimeEndpoint == nil {
            Label(
                "Resolve the endpoint configuration before running Smoke Console.",
                systemImage: "exclamationmark.triangle"
            )
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    @ViewBuilder
    private var responsePanel: some View {
        if let responseText {
            VStack(alignment: .leading, spacing: 6) {
                Text("Smoke Response")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)

                metricsSummary

                Text(responseText)
                    .font(.system(.body, design: .monospaced))
                    .textSelection(.enabled)
                    .padding(10)
                    .frame(maxWidth: .infinity, minHeight: 260, alignment: .topLeading)
                    .background(.black.opacity(0.22), in: RoundedRectangle(cornerRadius: 6))
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(Color.white.opacity(0.08), lineWidth: 1)
                    )
            }
        } else if let errorMessage {
            VStack(alignment: .leading, spacing: 6) {
                metricsSummary

                Label(errorMessage, systemImage: "exclamationmark.triangle")
                    .font(.caption)
                    .foregroundStyle(.red)
                    .padding(10)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(.red.opacity(0.08), in: RoundedRectangle(cornerRadius: 6))
            }
        } else {
            ContentUnavailableView(
                "No Smoke Result",
                systemImage: "checkmark.circle",
                description: Text("Run a local endpoint smoke request to show the latest response here.")
            )
            .frame(maxWidth: .infinity, minHeight: 180)
        }
    }

    @ViewBuilder
    private var metricsSummary: some View {
        if let resultMetrics {
            ViewThatFits(in: .horizontal) {
                HStack(spacing: 8) {
                    metricsBadges(for: resultMetrics)
                }

                VStack(alignment: .leading, spacing: 8) {
                    metricsBadges(for: resultMetrics)
                }
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        } else if let failureMetrics {
            ViewThatFits(in: .horizontal) {
                HStack(spacing: 8) {
                    metricsBadges(for: failureMetrics)
                }

                VStack(alignment: .leading, spacing: 8) {
                    metricsBadges(for: failureMetrics)
                }
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        }
    }

    @ViewBuilder
    private func metricsBadges(for result: ClientSmokeResult) -> some View {
        if let outputTokensPerSecond = result.outputTokensPerSecond {
            metricBadge(
                title: outputRateTitle(for: result),
                value: formattedApproximateRate(outputTokensPerSecond),
                isProminent: true
            )
        }
        if let startedAt = result.startedAt {
            metricBadge(title: "Started", value: formattedStartedAt(startedAt))
        }
        if let requestURL = result.requestURL {
            metricBadge(title: "Request URL", value: requestURL, valueLineLimit: 1)
        }
        metricBadge(title: "Elapsed", value: formattedElapsed(result.elapsedSeconds))
        metricBadge(title: "Characters", value: "\(result.outputCharacterCount)")
        if let finishReason = result.finishReason {
            metricBadge(title: "Finish Reason", value: finishReason)
        }
        if let runtimeUsage = result.runtimeUsage {
            metricBadge(title: "Usage Reported by Runtime", value: formattedRuntimeUsage(runtimeUsage))
        } else {
            if let approximateOutputTokenCount = result.approximateOutputTokenCount {
                metricBadge(title: "Approx Output Tokens", value: "\(approximateOutputTokenCount)")
            }
        }
        metricBadge(title: "Request Mode", value: displayRequestMode(result.requestMode))
        metricBadge(title: "Timeout Used", value: "\(result.timeoutSeconds)s")
    }

    @ViewBuilder
    private func metricsBadges(for metrics: SmokeFailureMetrics) -> some View {
        if let startedAt = metrics.startedAt {
            metricBadge(title: "Started", value: formattedStartedAt(startedAt))
        }
        if let requestURL = metrics.requestURL {
            metricBadge(title: "Request URL", value: requestURL, valueLineLimit: 1)
        }
        metricBadge(title: "Elapsed", value: formattedElapsed(metrics.elapsedSeconds))
        metricBadge(title: "Request Mode", value: displayRequestMode(metrics.requestMode))
        metricBadge(title: "Timeout Used", value: "\(metrics.timeoutSeconds)s")
    }

    private func metricBadge(
        title: LocalizedStringKey,
        value: String,
        isProminent: Bool = false,
        valueLineLimit: Int? = nil
    ) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.caption2.weight(.semibold))
                .textCase(.uppercase)
            Text(value)
                .font(.system(isProminent ? .body : .caption, design: .monospaced).weight(isProminent ? .semibold : .regular))
                .lineLimit(valueLineLimit)
                .truncationMode(.middle)
                .textSelection(.enabled)
        }
        .padding(.horizontal, isProminent ? 10 : 8)
        .padding(.vertical, isProminent ? 7 : 5)
        .background((isProminent ? Color.accentColor.opacity(0.22) : Color.black.opacity(0.14)), in: RoundedRectangle(cornerRadius: 6))
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .stroke(isProminent ? Color.accentColor.opacity(0.24) : Color.clear, lineWidth: 1)
        )
    }

    private var isServerRunning: Bool {
        if case .running = controller.status {
            return true
        }

        return false
    }

    private var canRunSmoke: Bool {
        isServerRunning &&
            !isRunning &&
            controller.runtimeEndpoint != nil &&
            !isPromptEmpty
    }

    private var isPromptEmpty: Bool {
        prompt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private func runSmoke() {
        guard let endpoint = controller.runtimeEndpoint, canRunSmoke else {
            return
        }

        isRunning = true
        responseText = nil
        resultMetrics = nil
        failureMetrics = nil
        errorMessage = nil
        didCopy = false
        let request = ClientSmokeRequest(
            baseURL: endpoint.apiBaseURLString,
            apiKey: endpoint.apiKey,
            model: endpoint.modelID,
            userText: prompt
        )
        let startedAt = Date()

        Task {
            do {
                let result = try await ClientSmokeClient().run(request)
                await MainActor.run {
                    responseText = result.responseText
                    resultMetrics = result
                    failureMetrics = nil
                    isRunning = false
                }
            } catch let smokeError as ClientSmokeError {
                await MainActor.run {
                    resultMetrics = nil
                    failureMetrics = SmokeFailureMetrics(
                        startedAt: startedAt,
                        elapsedSeconds: Date().timeIntervalSince(startedAt),
                        requestMode: .nonStreaming,
                        timeoutSeconds: request.timeoutSeconds,
                        requestURL: smokeError.requestURL ?? request.chatCompletionsURL
                    )
                    errorMessage = smokeError.message
                    isRunning = false
                }
            } catch {
                await MainActor.run {
                    resultMetrics = nil
                    failureMetrics = SmokeFailureMetrics(
                        startedAt: startedAt,
                        elapsedSeconds: Date().timeIntervalSince(startedAt),
                        requestMode: .nonStreaming,
                        timeoutSeconds: request.timeoutSeconds,
                        requestURL: request.chatCompletionsURL
                    )
                    errorMessage = error.localizedDescription
                    isRunning = false
                }
            }
        }
    }

    private var copyableResult: String? {
        if let responseText {
            return copyableSuccessResult(responseText)
        }

        return copyableErrorResult
    }

    private func copyableSuccessResult(_ responseText: String) -> String {
        guard let resultMetrics else {
            return responseText
        }

        return [
            String(localized: "Smoke Response"),
            responseText,
            "",
            String(localized: "Smoke Metrics"),
            copyMetricLines(for: resultMetrics).joined(separator: "\n")
        ].joined(separator: "\n")
    }

    private var copyableErrorResult: String? {
        guard let errorMessage else {
            return nil
        }

        var sections = [
            String(localized: "Smoke Error"),
            errorMessage
        ]

        if let failureMetrics {
            sections.append("")
            sections.append(String(localized: "Smoke Metrics"))
            sections.append(copyMetricLines(for: failureMetrics).joined(separator: "\n"))
        }

        return sections.joined(separator: "\n")
    }

    private func copyMetricLines(for result: ClientSmokeResult) -> [String] {
        var lines: [String] = []

        if let startedAt = result.startedAt {
            lines.append("\(String(localized: "Started")): \(formattedStartedAt(startedAt))")
        }
        if let requestURL = result.requestURL {
            lines.append("\(String(localized: "Request URL")): \(requestURL)")
        }
        if let outputTokensPerSecond = result.outputTokensPerSecond {
            let title = outputRateCopyTitle(for: result)
            lines.append("\(title): \(formattedApproximateRate(outputTokensPerSecond))")
        }
        lines.append("\(String(localized: "Elapsed")): \(formattedElapsed(result.elapsedSeconds))")
        lines.append("\(String(localized: "Characters")): \(result.outputCharacterCount)")
        if let finishReason = result.finishReason {
            lines.append("\(String(localized: "Finish Reason")): \(finishReason)")
        }
        if let runtimeUsage = result.runtimeUsage {
            lines.append("\(String(localized: "Usage Reported by Runtime")): \(formattedRuntimeUsage(runtimeUsage))")
        } else {
            if let approximateOutputTokenCount = result.approximateOutputTokenCount {
                lines.append("\(String(localized: "Approx Output Tokens")): \(approximateOutputTokenCount)")
            }
        }
        lines.append("\(String(localized: "Request Mode")): \(displayRequestMode(result.requestMode))")
        lines.append("\(String(localized: "Timeout Used")): \(result.timeoutSeconds)s")

        return lines
    }

    private func copyMetricLines(for metrics: SmokeFailureMetrics) -> [String] {
        var lines: [String] = []

        if let startedAt = metrics.startedAt {
            lines.append("\(String(localized: "Started")): \(formattedStartedAt(startedAt))")
        }
        if let requestURL = metrics.requestURL {
            lines.append("\(String(localized: "Request URL")): \(requestURL)")
        }
        lines.append("\(String(localized: "Elapsed")): \(formattedElapsed(metrics.elapsedSeconds))")
        lines.append("\(String(localized: "Request Mode")): \(displayRequestMode(metrics.requestMode))")
        lines.append("\(String(localized: "Timeout Used")): \(metrics.timeoutSeconds)s")

        return lines
    }

    private func copyResult() {
        guard let copyableResult else {
            return
        }

        PasteboardWriter.copy(copyableResult)
        copyGeneration += 1
        let generation = copyGeneration

        withAnimation(.easeInOut(duration: 0.15)) {
            didCopy = true
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.6) {
            guard copyGeneration == generation else {
                return
            }

            withAnimation(.easeInOut(duration: 0.2)) {
                didCopy = false
            }
        }
    }

    private func clearResult() {
        responseText = nil
        resultMetrics = nil
        failureMetrics = nil
        errorMessage = nil
        didCopy = false
    }

    private func formattedElapsed(_ seconds: Double) -> String {
        String(format: "%.2fs", seconds)
    }

    private func formattedStartedAt(_ date: Date) -> String {
        DateFormatter.localizedString(from: date, dateStyle: .none, timeStyle: .medium)
    }

    private func formattedRuntimeUsage(_ usage: ClientSmokeResult.Usage) -> String {
        String(
            format: String(localized: "smoke.usage.summary"),
            formattedTokenCount(usage.promptTokens),
            formattedTokenCount(usage.completionTokens),
            formattedTokenCount(usage.totalTokens)
        )
    }

    private func formattedTokenCount(_ count: Int?) -> String {
        guard let count else {
            return String(localized: "smoke.metric.unavailable")
        }

        return "\(count)"
    }

    private func formattedApproximateRate(_ tokensPerSecond: Double) -> String {
        String(format: "%.1f/s", tokensPerSecond)
    }

    private func outputRateTitle(for result: ClientSmokeResult) -> LocalizedStringKey {
        if result.usesRuntimeReportedOutputRate {
            return "Runtime TPS"
        }

        return result.usesApproximateOutputRate ? "Approx TPS" : "TPS"
    }

    private func outputRateCopyTitle(for result: ClientSmokeResult) -> String {
        if result.usesRuntimeReportedOutputRate {
            return String(localized: "Runtime TPS")
        }

        return result.usesApproximateOutputRate ? String(localized: "Approx TPS") : String(localized: "TPS")
    }

    private func displayRequestMode(_ requestMode: ClientSmokeResult.RequestMode) -> String {
        switch requestMode {
        case .nonStreaming:
            return String(localized: "Non-streaming")
        }
    }
}

private struct SmokeFailureMetrics: Equatable {
    var startedAt: Date?
    var elapsedSeconds: Double
    var requestMode: ClientSmokeResult.RequestMode
    var timeoutSeconds: Int
    var requestURL: String?
}
