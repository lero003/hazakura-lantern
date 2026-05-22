import SwiftUI
import HazakuraLLMManagerCore

struct SetupGuideView: View {
    @ObservedObject var controller: ServerController
    @State private var selectedPresetIntent: LlamaServerPresetIntent = .standard
    @State private var isHomebrewCopied = false
    @State private var isUpdateCommandCopied = false

    private static let ggufModelSearchURL = URL(string: "https://huggingface.co/models?search=gguf")

    private var selectedPreset: LlamaServerPreset {
        LlamaServerPreset.preset(for: selectedPresetIntent)
    }

    // ステップ完了判定
    private var isStep1Completed: Bool {
        !controller.configuration.runtimeExecutablePath.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private var isStep2Completed: Bool {
        !controller.configuration.modelPath.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private var isStep3Completed: Bool {
        // ランタイムとモデルの両方が指定されていれば、設定適用可能（完了とみなす）
        isStep1Completed && isStep2Completed
    }

    private var isStep4Completed: Bool {
        guard controller.status == .running else {
            return false
        }
        if case .healthy = controller.endpointHealthStatus {
            return true
        }
        return false
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // ヘッダー部分
            HStack(spacing: 10) {
                Image(systemName: "laurel.leading")
                    .font(.title2)
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.cyan, .purple, .pink],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )

                VStack(alignment: .leading, spacing: 2) {
                    Text("Setup Guide")
                        .font(.headline)
                        .foregroundStyle(.primary)
                    Text("Follow steps to light your lantern")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
            .padding(.bottom, 16)
            .background(.ultraThinMaterial.opacity(0.3))
            .overlay(
                VStack {
                    Spacer()
                    Rectangle()
                        .fill(Color.white.opacity(0.08))
                        .frame(height: 1)
                }
            )

            // スクロール可能なステップリスト
            ScrollView {
                VStack(spacing: 16) {
                    // Step 1
                    stepCard(
                        stepNumber: 1,
                        title: "Prepare llama-server",
                        description: "llama-server binary is required to host local model processes.",
                        isCompleted: isStep1Completed,
                        completeAccessibilityHint: "A llama-server executable is selected.",
                        incompleteAccessibilityHint: "Select an installed llama-server executable or choose one manually."
                    ) {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("If not installed, run this command via Terminal:")
                                .font(.caption)
                                .foregroundStyle(.secondary)

                            ViewThatFits(in: .horizontal) {
                                HStack {
                                    homebrewCommandLabel

                                    Spacer()

                                    copyHomebrewButton
                                }

                                VStack(alignment: .leading, spacing: 8) {
                                    homebrewCommandLabel
                                    copyHomebrewButton
                                }
                            }

                            Text("To update an existing Homebrew runtime, run this command manually:")
                                .font(.caption)
                                .foregroundStyle(.secondary)

                            ViewThatFits(in: .horizontal) {
                                HStack {
                                    updateCommandLabel

                                    Spacer()

                                    copyUpdateCommandButton
                                }

                                VStack(alignment: .leading, spacing: 8) {
                                    updateCommandLabel
                                    copyUpdateCommandButton
                                }
                            }

                            Divider()
                                .padding(.vertical, 2)

                            if !controller.detectedRuntimeExecutablePaths.isEmpty {
                                Text("Installed runtime detected:")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)

                                ViewThatFits(in: .horizontal) {
                                    HStack {
                                        installedRuntimeMenu
                                        refreshInstalledRuntimeButton
                                        Spacer()
                                    }

                                    VStack(alignment: .leading, spacing: 8) {
                                        installedRuntimeMenu
                                        refreshInstalledRuntimeButton
                                    }
                                }
                            } else {
                                VStack(alignment: .leading, spacing: 8) {
                                    Label(
                                        "no_runtime_detected_guide",
                                        systemImage: "magnifyingglass"
                                    )
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .fixedSize(horizontal: false, vertical: true)

                                    HStack {
                                        refreshInstalledRuntimeButton
                                        Spacer()
                                    }
                                }
                            }

                            HStack {
                                Button {
                                    if let path = FilePanel.chooseFile(allowedExtensions: nil) {
                                        controller.selectRuntimeExecutablePath(path)
                                    }
                                } label: {
                                    Label("Choose Runtime", systemImage: "folder")
                                }
                                .buttonStyle(SecondaryButtonStyle())

                                Spacer()
                            }

                            if isStep1Completed {
                                pathLabel(path: controller.configuration.runtimeExecutablePath)
                            }
                        }
                    }

                    // Step 2
                    stepCard(
                        stepNumber: 2,
                        title: "Prepare GGUF Model",
                        description: "Select a .gguf format model file to run on the server.",
                        isCompleted: isStep2Completed,
                        completeAccessibilityHint: "A GGUF model file is selected.",
                        incompleteAccessibilityHint: "Choose an existing local GGUF model file."
                    ) {
                        VStack(alignment: .leading, spacing: 10) {
                            if let ggufModelSearchURL = Self.ggufModelSearchURL {
                                HStack {
                                    Link(destination: ggufModelSearchURL) {
                                        Label("Find on Hugging Face", systemImage: "safari")
                                            .font(.caption)
                                    }
                                    .buttonStyle(SecondaryButtonStyle())
                                    Spacer()
                                }
                            }

                            Divider()
                                .padding(.vertical, 2)

                            HStack {
                                Button {
                                    if let path = FilePanel.chooseFile(allowedExtensions: ["gguf"]) {
                                        controller.selectModelPath(path)
                                    }
                                } label: {
                                    Label("Choose GGUF Model", systemImage: "folder")
                                }
                                .buttonStyle(SecondaryButtonStyle())
                                Spacer()
                            }

                            if isStep2Completed {
                                pathLabel(path: controller.configuration.modelPath)
                            }
                        }
                    }

                    // Step 3
                    stepCard(
                        stepNumber: 3,
                        title: "Apply Recommended Preset",
                        description: "Configure basic settings based on your Mac environment.",
                        isCompleted: isStep3Completed,
                        completeAccessibilityHint: "Runtime and model are selected; review and apply a preset if needed.",
                        incompleteAccessibilityHint: "Select a runtime and model before applying a preset."
                    ) {
                        VStack(alignment: .leading, spacing: 10) {
                            Picker("Preset", selection: $selectedPresetIntent) {
                                ForEach(LlamaServerPreset.all, id: \.intent) { preset in
                                    Text(preset.displayName)
                                        .tag(preset.intent)
                                }
                            }
                            .labelsHidden()
                            .pickerStyle(.menu)
                            .disabled(!isStep1Completed || !isStep2Completed)

                            Text(selectedPreset.previewSummary)
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                                .lineLimit(2)

                            Button {
                                controller.applyPreset(selectedPreset)
                            } label: {
                                Label("Apply to Configuration", systemImage: "slider.horizontal.3")
                            }
                            .buttonStyle(SecondaryButtonStyle())
                            .disabled(!isStep1Completed || !isStep2Completed)
                        }
                    }

                    // Step 4
                    stepCard(
                        stepNumber: 4,
                        title: "Launch & Connect",
                        description: "Start your server process and test API availability.",
                        isCompleted: isStep4Completed,
                        completeAccessibilityHint: "The server is running and the latest manual health check is healthy.",
                        incompleteAccessibilityHint: "Start the server, then run a manual health check."
                    ) {
                        VStack(alignment: .leading, spacing: 10) {
                            ViewThatFits(in: .horizontal) {
                                HStack(spacing: 12) {
                                    launchToggleButton
                                    checkHealthButton
                                }

                                VStack(alignment: .leading, spacing: 8) {
                                    launchToggleButton
                                    checkHealthButton
                                }
                            }

                            HStack(spacing: 8) {
                                Text("Process Status:")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                Text(controller.status.title)
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(statusColor(controller.status))
                            }

                            HStack(spacing: 8) {
                                Text("API Health:")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                Text(controller.endpointHealthStatus.title)
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(healthColor(controller.endpointHealthStatus))
                            }

                            if let endpoint = controller.runtimeEndpoint {
                                Divider()
                                    .padding(.vertical, 2)

                                Text("Client Connection URL:")
                                    .font(.caption2.weight(.bold))
                                    .foregroundStyle(.secondary)

                                HStack {
                                    Text(endpoint.apiBaseURLString)
                                        .font(.system(.caption, design: .monospaced))
                                        .lineLimit(1)
                                        .textSelection(.enabled)

                                    Spacer()

                                    Button {
                                        PasteboardWriter.copy(endpoint.apiBaseURLString)
                                    } label: {
                                        Label("Copy Endpoint", systemImage: "doc.on.doc")
                                            .labelStyle(.iconOnly)
                                            .font(.caption)
                                    }
                                    .buttonStyle(.plain)
                                    .accessibilityHint(Text("Copy the client connection URL to the clipboard."))
                                    .help("Copy Endpoint")
                                }
                            }
                        }
                    }
                }
                .padding(20)
            }
        }
    }

    // カードの共通UIコンポーネント
    private func stepCard<Content: View>(
        stepNumber: Int,
        title: String,
        description: String,
        isCompleted: Bool,
        completeAccessibilityHint: LocalizedStringKey,
        incompleteAccessibilityHint: LocalizedStringKey,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 8) {
                // ステップインジケータ
                ZStack {
                    Circle()
                        .fill(isCompleted ? Color.green.opacity(0.15) : Color.white.opacity(0.08))
                        .frame(width: 24, height: 24)

                    if isCompleted {
                        Image(systemName: "checkmark")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(.green)
                    } else {
                        Text("\(stepNumber)")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(.secondary)
                    }
                }
                .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: 4) {
                    Text(LocalizedStringKey(title))
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(isCompleted ? Color.primary : Color.primary.opacity(0.85))
                    Text(LocalizedStringKey(description))
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer()
            }
            .accessibilityElement(children: .combine)
            .accessibilityValue(Text(LocalizedStringKey(isCompleted ? "Complete" : "Incomplete")))
            .accessibilityHint(Text(isCompleted ? completeAccessibilityHint : incompleteAccessibilityHint))

            content()
                .padding(.leading, 32)
        }
        .padding(14)
        .background(.white.opacity(0.03))
        .cornerRadius(10)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(
                    LinearGradient(
                        colors: isCompleted ?
                            [Color.green.opacity(0.2), Color.green.opacity(0.05)] :
                            [Color.white.opacity(0.1), Color.white.opacity(0.02)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        )
    }

    private func pathLabel(path: String) -> some View {
        HStack(spacing: 4) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(.green)
                .font(.caption)
            Text(URL(fileURLWithPath: path).lastPathComponent)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .help(path)
        }
        .padding(.top, 4)
    }

    private var installedRuntimeMenu: some View {
        Menu {
            ForEach(controller.detectedRuntimeExecutablePaths, id: \.self) { path in
                Button {
                    controller.selectRuntimeExecutablePath(path)
                } label: {
                    Text(runtimePathMenuLabel(path))
                }
            }
        } label: {
            Label("Installed Runtime", systemImage: "checkmark.seal")
        }
        .buttonStyle(SecondaryButtonStyle())
    }

    private var refreshInstalledRuntimeButton: some View {
        Button {
            controller.refreshDetectedRuntimeExecutablePaths()
        } label: {
            Label("Scan Installed", systemImage: "arrow.clockwise")
        }
        .buttonStyle(SecondaryButtonStyle())
    }

    private func runtimePathMenuLabel(_ path: String) -> String {
        let name = URL(fileURLWithPath: path).lastPathComponent
        guard !name.isEmpty else {
            return path
        }

        return "\(name) - \(path)"
    }

    private var homebrewCommandLabel: some View {
        Text("brew install llama.cpp")
            .font(.system(.caption, design: .monospaced))
            .lineLimit(1)
            .minimumScaleFactor(0.85)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color.black.opacity(0.3), in: RoundedRectangle(cornerRadius: 6))
    }

    private var copyHomebrewButton: some View {
        Button {
            PasteboardWriter.copy("brew install llama.cpp")
            isHomebrewCopied = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                isHomebrewCopied = false
            }
        } label: {
            Label(
                isHomebrewCopied ? "Copied!" : "Copy",
                systemImage: isHomebrewCopied ? "checkmark" : "doc.on.doc"
            )
            .font(.caption)
        }
        .buttonStyle(SecondaryButtonStyle())
    }

    private var updateCommandLabel: some View {
        Text("brew upgrade llama.cpp")
            .font(.system(.caption, design: .monospaced))
            .lineLimit(1)
            .minimumScaleFactor(0.85)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color.black.opacity(0.3), in: RoundedRectangle(cornerRadius: 6))
    }

    private var copyUpdateCommandButton: some View {
        Button {
            PasteboardWriter.copy("brew upgrade llama.cpp")
            isUpdateCommandCopied = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                isUpdateCommandCopied = false
            }
        } label: {
            Label(
                isUpdateCommandCopied ? "Copied!" : "Copy",
                systemImage: isUpdateCommandCopied ? "checkmark" : "doc.on.doc"
            )
            .font(.caption)
        }
        .buttonStyle(SecondaryButtonStyle())
    }

    private var launchToggleButton: some View {
        Button {
            if controller.canStop {
                controller.stop()
            } else {
                controller.start()
            }
        } label: {
            Label(
                controller.canStop ? "Stop Server" : "Start Server",
                systemImage: controller.canStop ? "stop.fill" : "play.fill"
            )
        }
        .buttonStyle(controller.canStop ? AnyButtonStyle(SecondaryButtonStyle()) : AnyButtonStyle(PrimaryButtonStyle()))
        .disabled(!controller.canStart && !controller.canStop)
    }

    private var checkHealthButton: some View {
        Button {
            controller.checkEndpointHealth()
        } label: {
            Label("Check Health", systemImage: "waveform.path.ecg")
                .font(.caption)
        }
        .buttonStyle(SecondaryButtonStyle())
        .disabled(!controller.canCheckEndpointHealth)
    }

    private func statusColor(_ status: ServerStatus) -> Color {
        switch status {
        case .running:
            return .green
        case .starting, .loading, .restarting:
            return .orange
        case .stopping:
            return .yellow
        case .stopped:
            return .secondary
        case .error:
            return .red
        }
    }

    private func healthColor(_ status: EndpointHealthStatus) -> Color {
        switch status {
        case .healthy:
            return .green
        case .unhealthy:
            return .red
        case .checking:
            return .orange
        case .unchecked:
            return .secondary
        }
    }
}

// 任意のButtonStyleを適用するためのラッパー
private struct AnyButtonStyle: ButtonStyle {
    private let makeBodyBlock: (Configuration) -> AnyView

    init<S: ButtonStyle>(_ style: S) {
        self.makeBodyBlock = { configuration in
            AnyView(style.makeBody(configuration: configuration))
        }
    }

    func makeBody(configuration: Configuration) -> some View {
        makeBodyBlock(configuration)
    }
}
