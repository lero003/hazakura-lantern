import SwiftUI
import HazakuraLLMManagerCore

struct DashboardView: View {
    @ObservedObject var controller: ServerController
    var onOpenSetupGuide: () -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                GroupBox("Server Controls") {
                    VStack(alignment: .leading, spacing: 16) {
                        if let launchSetupHint = controller.launchSetupHint {
                            ViewThatFits(in: .horizontal) {
                                setupHintRow(launchSetupHint)
                                VStack(alignment: .leading, spacing: 6) {
                                    setupHintLabel(launchSetupHint)
                                    setupGuideButton
                                }
                            }
                        }

                        ViewThatFits(in: .horizontal) {
                            HStack(spacing: 12) {
                                serverControlButtons
                                Spacer()
                                lastErrorLabel
                            }

                            VStack(alignment: .leading, spacing: 10) {
                                serverControlButtons
                                lastErrorLabel
                            }
                        }
                    }
                    .padding(.vertical, 8)
                }

                EndpointView(controller: controller)
                CommandPreviewView(controller: controller)
            }
            .padding(24)
        }
    }

    private var serverControlButtons: some View {
        HStack(spacing: 12) {
            Button {
                controller.start()
            } label: {
                Label("Start", systemImage: "play.fill")
            }
            .buttonStyle(PrimaryButtonStyle())
            .disabled(!controller.canStart)

            Button {
                controller.stop()
            } label: {
                Label("Stop", systemImage: "stop.fill")
            }
            .buttonStyle(SecondaryButtonStyle())
            .disabled(!controller.canStop)

            Button {
                controller.restart()
            } label: {
                Label("Restart", systemImage: "arrow.clockwise")
            }
            .buttonStyle(SecondaryButtonStyle())
            .disabled(!controller.canRestart)
        }
    }

    @ViewBuilder
    private var lastErrorLabel: some View {
        if let message = controller.lastErrorMessage {
            Label(message, systemImage: "exclamationmark.triangle")
                .foregroundStyle(.red)
                .font(.caption)
                .lineLimit(2)
        }
    }

    private func setupHintRow(_ launchSetupHint: String) -> some View {
        HStack(spacing: 8) {
            setupHintLabel(launchSetupHint)
            setupGuideButton
        }
    }

    private func setupHintLabel(_ launchSetupHint: String) -> some View {
        Label(launchSetupHint, systemImage: "info.circle")
            .font(.caption)
            .foregroundStyle(.secondary)
    }

    private var setupGuideButton: some View {
        Button(action: onOpenSetupGuide) {
            Label("Open Setup Guide", systemImage: "laurel.leading")
                .font(.caption)
        }
        .buttonStyle(.link)
    }
}
