import SwiftUI

struct HelpTooltip: View {
    let titleKey: String
    let descriptionKey: String
    let tipsKey: String

    @Environment(\.locale) private var locale
    @State private var isShowingPopover = false

    var body: some View {
        Button {
            isShowingPopover = true
        } label: {
            Image(systemName: "questionmark.circle")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(explanationLabel)
        .help(explanationLabel)
        .popover(isPresented: $isShowingPopover, arrowEdge: .trailing) {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text(LocalizedStringKey(titleKey))
                        .font(.headline)
                        .foregroundStyle(.primary)
                    Spacer()
                }

                Divider()

                VStack(alignment: .leading, spacing: 4) {
                    Text("Description")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundStyle(.secondary)

                    Text(LocalizedStringKey(descriptionKey))
                        .font(.body)
                        .foregroundStyle(.primary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("Tips")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundStyle(.secondary)

                    Text(LocalizedStringKey(tipsKey))
                        .font(.callout)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.top, 4)
            }
            .padding(14)
            .frame(width: 320)
        }
    }

    private var explanationLabel: String {
        let title = String(
            localized: String.LocalizationValue(titleKey),
            bundle: .module,
            locale: locale
        )
        return String(
            localized: String.LocalizationValue("Show explanation for \(title)"),
            bundle: .module,
            locale: locale
        )
    }
}

// プリセットデータの整理
extension HelpTooltip {
    static func runtime() -> HelpTooltip {
        HelpTooltip(
            titleKey: "tooltip.runtime.title",
            descriptionKey: "tooltip.runtime.description",
            tipsKey: "tooltip.runtime.tips"
        )
    }

    static func model() -> HelpTooltip {
        HelpTooltip(
            titleKey: "tooltip.model.title",
            descriptionKey: "tooltip.model.description",
            tipsKey: "tooltip.model.tips"
        )
    }

    static func port() -> HelpTooltip {
        HelpTooltip(
            titleKey: "tooltip.port.title",
            descriptionKey: "tooltip.port.description",
            tipsKey: "tooltip.port.tips"
        )
    }

    static func contextSize() -> HelpTooltip {
        HelpTooltip(
            titleKey: "tooltip.context.title",
            descriptionKey: "tooltip.context.description",
            tipsKey: "tooltip.context.tips"
        )
    }

    static func threads() -> HelpTooltip {
        HelpTooltip(
            titleKey: "tooltip.threads.title",
            descriptionKey: "tooltip.threads.description",
            tipsKey: "tooltip.threads.tips"
        )
    }

    static func gpuLayers() -> HelpTooltip {
        HelpTooltip(
            titleKey: "tooltip.gpu_layers.title",
            descriptionKey: "tooltip.gpu_layers.description",
            tipsKey: "tooltip.gpu_layers.tips"
        )
    }

    static func additionalArguments() -> HelpTooltip {
        HelpTooltip(
            titleKey: "tooltip.additional_args.title",
            descriptionKey: "tooltip.additional_args.description",
            tipsKey: "tooltip.additional_args.tips"
        )
    }
}
