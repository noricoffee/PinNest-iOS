import SwiftUI

// MARK: - HistoryEntry（プロトタイプ用）

struct HistoryEntry: Identifiable {
    let id = UUID()
    let item: PinPreviewItem
    let addedAt: Date

    var timeString: String {
        let f = DateFormatter()
        f.dateFormat = "HH:mm"
        return f.string(from: addedAt)
    }

    var sectionDateString: String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "ja_JP")
        f.dateFormat = "M月d日"
        return f.string(from: addedAt)
    }
}

extension HistoryEntry {
    static let samples: [HistoryEntry] = {
        let cal = Calendar.current
        let base = cal.startOfDay(for: Date())

        func dt(_ daysAgo: Int, _ h: Int, _ m: Int) -> Date {
            let day = cal.date(byAdding: .day, value: -daysAgo, to: base)!
            return cal.date(bySettingHour: h, minute: m, second: 0, of: day)!
        }

        return [
            HistoryEntry(item: PinPreviewItem.samples[9], addedAt: dt(2, 20, 0)),
            HistoryEntry(item: PinPreviewItem.samples[3], addedAt: dt(1, 14, 20)),
            HistoryEntry(item: PinPreviewItem.samples[6], addedAt: dt(1, 18, 5)),
            HistoryEntry(item: PinPreviewItem.samples[2], addedAt: dt(1, 22, 30)),
            HistoryEntry(item: PinPreviewItem.samples[0], addedAt: dt(0, 9, 11)),
            HistoryEntry(item: PinPreviewItem.samples[1], addedAt: dt(0, 10, 24)),
        ]
    }()
}

// MARK: - HistoryView

struct HistoryView: View {
    private let timelineColumnWidth: CGFloat = 20
    private let rowHalfHeight: CGFloat = 32

    private var groupedEntries: [(dateLabel: String, date: Date, entries: [HistoryEntry])] {
        let sorted = HistoryEntry.samples.sorted { $0.addedAt < $1.addedAt }
        let cal = Calendar.current
        var groups: [(dateLabel: String, date: Date, entries: [HistoryEntry])] = []
        for entry in sorted {
            let day = cal.startOfDay(for: entry.addedAt)
            if let idx = groups.firstIndex(where: { cal.isDate($0.date, inSameDayAs: day) }) {
                groups[idx].entries.append(entry)
            } else {
                groups.append((dateLabel: entry.sectionDateString, date: day, entries: [entry]))
            }
        }
        return groups
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 0) {
                    timelineContent
                }
                .padding(.bottom, 104)
            }
            .scrollIndicators(.hidden)
            .navigationTitle("履歴")
            .navigationBarTitleDisplayMode(.large)
        }
    }

    @ViewBuilder
    private var timelineContent: some View {
        let groups = groupedEntries
        ForEach(Array(groups.enumerated()), id: \.element.date) { gi, group in
            let isLastGroup = gi == groups.count - 1
            DateSectionHeader(
                label: group.dateLabel,
                showTopLine: gi > 0,
                timelineColumnWidth: timelineColumnWidth
            )
            ForEach(Array(group.entries.enumerated()), id: \.element.id) { ei, entry in
                let isLastItem = isLastGroup && ei == group.entries.count - 1
                HistoryRowView(
                    entry: entry,
                    showBottomLine: !isLastItem,
                    rowHalfHeight: rowHalfHeight,
                    timelineColumnWidth: timelineColumnWidth
                )
            }
        }
    }
}

// MARK: - DateSectionHeader

private struct DateSectionHeader: View {
    let label: String
    let showTopLine: Bool
    let timelineColumnWidth: CGFloat

    var body: some View {
        HStack(alignment: .center, spacing: 0) {
            Text(label)
                .font(.footnote.weight(.semibold))
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .trailing)
                .padding(.trailing, 12)

            VStack(spacing: 0) {
                if showTopLine {
                    Rectangle()
                        .fill(Color(.separator))
                        .frame(width: 1, height: 12)
                } else {
                    Color.clear.frame(height: 12)
                }
                Circle()
                    .stroke(Color(.separator), lineWidth: 1)
                    .frame(width: 6, height: 6)
                Rectangle()
                    .fill(Color(.separator))
                    .frame(width: 1, height: 12)
            }
            .frame(width: timelineColumnWidth)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 2)
    }
}

// MARK: - HistoryRowView

private struct HistoryRowView: View {
    let entry: HistoryEntry
    let showBottomLine: Bool
    let rowHalfHeight: CGFloat
    let timelineColumnWidth: CGFloat

    var body: some View {
        HStack(alignment: .center, spacing: 0) {
            HStack(spacing: 8) {
                Text(entry.item.title)
                    .font(.subheadline)
                    .lineLimit(1)
                    .frame(maxWidth: .infinity, alignment: .trailing)

                Image(systemName: entry.item.contentType.iconName)
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .frame(width: 20)

                Text(entry.timeString)
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.secondary)
                    .frame(width: 40, alignment: .trailing)
            }
            .padding(.trailing, 12)

            VStack(spacing: 0) {
                Rectangle()
                    .fill(Color(.separator))
                    .frame(width: 1, height: rowHalfHeight)

                Image(systemName: "pin.fill")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Color.accentColor)
                    .rotationEffect(.degrees(45))

                if showBottomLine {
                    Rectangle()
                        .fill(Color(.separator))
                        .frame(width: 1, height: rowHalfHeight)
                } else {
                    Color.clear.frame(height: rowHalfHeight)
                }
            }
            .frame(width: timelineColumnWidth)
        }
        .padding(.horizontal, 16)
        .accessibilityLabel("\(entry.item.title)、\(entry.timeString)に追加")
    }
}

// MARK: - Preview

#Preview {
    HistoryView()
}
