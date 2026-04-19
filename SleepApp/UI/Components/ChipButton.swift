import SwiftUI

struct ChipButton: View {
    let title: String
    var icon: String? = nil
    @Binding var isSelected: Bool
    var color: Color = .sleepPurple

    var body: some View {
        Button {
            isSelected.toggle()
        } label: {
            HStack(spacing: Spacing.xxs) {
                if let icon {
                    Image(systemName: icon)
                        .font(.system(size: 12, weight: .medium))
                }
                Text(title)
                    .font(.labelLarge)
            }
            .foregroundStyle(isSelected ? .white : Color.textSecondary)
            .padding(.horizontal, Spacing.sm)
            .padding(.vertical, Spacing.xs)
            .background {
                Capsule()
                    .fill(isSelected ? color : Color.sleepElevated)
                    .overlay {
                        Capsule()
                            .strokeBorder(
                                isSelected ? color : Color.sleepBorder,
                                lineWidth: 1
                            )
                    }
            }
        }
        .buttonStyle(.plain)
        .animation(.spring(response: 0.25, dampingFraction: 0.7), value: isSelected)
    }
}

struct SelectableChipGroup: View {
    let options: [String]
    @Binding var selected: Set<String>
    var color: Color = .sleepPurple

    var body: some View {
        FlowLayout(spacing: Spacing.xs) {
            ForEach(options, id: \.self) { option in
                ChipButton(
                    title: option,
                    isSelected: Binding(
                        get: { selected.contains(option) },
                        set: { if $0 { selected.insert(option) } else { selected.remove(option) } }
                    ),
                    color: color
                )
            }
        }
    }
}

struct SingleSelectChipGroup: View {
    let options: [String]
    @Binding var selected: String?
    var color: Color = .sleepPurple

    var body: some View {
        FlowLayout(spacing: Spacing.xs) {
            ForEach(options, id: \.self) { option in
                ChipButton(
                    title: option,
                    isSelected: Binding(
                        get: { selected == option },
                        set: { if $0 { selected = option } else { selected = nil } }
                    ),
                    color: color
                )
            }
        }
    }
}

struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout Void) -> CGSize {
        let rows = computeRows(proposal: proposal, subviews: subviews)
        let height = rows.map(\.height).reduce(0, +) + CGFloat(max(rows.count - 1, 0)) * spacing
        return CGSize(width: proposal.width ?? 0, height: height)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout Void) {
        let rows = computeRows(proposal: proposal, subviews: subviews)
        var y = bounds.minY
        for row in rows {
            var x = bounds.minX
            for subview in row.subviews {
                let size = subview.sizeThatFits(.unspecified)
                subview.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(size))
                x += size.width + spacing
            }
            y += row.height + spacing
        }
    }

    private struct Row {
        var subviews: [LayoutSubview] = []
        var height: CGFloat = 0
    }

    private func computeRows(proposal: ProposedViewSize, subviews: Subviews) -> [Row] {
        let maxWidth = proposal.width ?? .infinity
        var rows: [Row] = []
        var currentRow = Row()
        var rowWidth: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if rowWidth + size.width > maxWidth && !currentRow.subviews.isEmpty {
                rows.append(currentRow)
                currentRow = Row()
                rowWidth = 0
            }
            currentRow.subviews.append(subview)
            currentRow.height = max(currentRow.height, size.height)
            rowWidth += size.width + spacing
        }
        if !currentRow.subviews.isEmpty { rows.append(currentRow) }
        return rows
    }
}
