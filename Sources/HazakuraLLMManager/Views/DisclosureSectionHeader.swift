import SwiftUI

struct DisclosureSectionHeader: View {
    let title: LocalizedStringKey
    @Binding var isExpanded: Bool

    var body: some View {
        Button {
            withAnimation(.snappy(duration: 0.16)) {
                isExpanded.toggle()
            }
        } label: {
            HStack(spacing: 6) {
                Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                    .font(.caption.weight(.semibold))
                    .frame(width: 12)

                Text(title)
                    .font(.callout)
                    .foregroundStyle(.secondary)

                Spacer(minLength: 0)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.vertical, 3)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .frame(maxWidth: .infinity, alignment: .leading)
        .contentShape(Rectangle())
        .accessibilityValue(isExpanded ? Text("Expanded") : Text("Collapsed"))
    }
}
