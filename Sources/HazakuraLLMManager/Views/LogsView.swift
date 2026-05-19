import SwiftUI
import HazakuraLLMManagerCore

struct LogsView: View {
    @ObservedObject var controller: ServerController

    var body: some View {
        GroupBox {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text("Logs")
                        .font(.headline)

                    Spacer()

                    Button {
                        controller.clearLogs()
                    } label: {
                        Label("Clear", systemImage: "trash")
                    }
                    .disabled(controller.logEntries.isEmpty)
                }

                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: 4) {
                            if controller.logEntries.isEmpty {
                                Text("No logs yet.")
                                    .foregroundStyle(.secondary)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(.vertical, 18)
                            } else {
                                ForEach(controller.logEntries) { entry in
                                    LogEntryRow(entry: entry)
                                        .id(entry.id)
                                }
                            }
                        }
                        .padding(10)
                    }
                    .frame(minHeight: 220, maxHeight: 320)
                    .background(.black.opacity(0.25), in: RoundedRectangle(cornerRadius: 8))
                    .overlay {
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.white.opacity(0.08), lineWidth: 1)
                    }
                    .onChange(of: controller.logEntries.count) {
                        guard let last = controller.logEntries.last else {
                            return
                        }

                        proxy.scrollTo(last.id, anchor: .bottom)
                    }
                }
            }
        }
    }
}

private struct LogEntryRow: View {
    var entry: LogEntry

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Text(entry.stream.rawValue)
                .font(.system(.caption2, design: .monospaced))
                .foregroundStyle(streamColor)
                .frame(width: 48, alignment: .leading)

            Text(entry.text)
                .font(.system(.caption, design: .monospaced))
                .foregroundStyle(.primary)
                .textSelection(.enabled)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var streamColor: Color {
        switch entry.stream {
        case .info:
            .secondary
        case .stdout:
            .blue
        case .stderr:
            .orange
        case .error:
            .red
        }
    }
}
