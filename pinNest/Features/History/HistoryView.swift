import ComposableArchitecture
import SwiftUI

// MARK: - HistoryView

struct HistoryView: View {
    @Bindable var store: StoreOf<HistoryReducer>
    @Environment(\.colorSchemePreference) private var colorSchemePreference

    private let timelineColumnWidth: CGFloat = 20
    private let rowHalfHeight: CGFloat = 32

    private var groupedPins: [(dateLabel: String, date: Date, pins: [Pin])] {
        let cal = Calendar.current
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ja_JP")
        formatter.dateFormat = "M月d日"

        var groups: [(dateLabel: String, date: Date, pins: [Pin])] = []
        for pin in store.pins {
            let day = cal.startOfDay(for: pin.createdAt)
            if let idx = groups.firstIndex(where: { cal.isDate($0.date, inSameDayAs: day) }) {
                groups[idx].pins.append(pin)
            } else {
                groups.append((
                    dateLabel: formatter.string(from: pin.createdAt),
                    date: day,
                    pins: [pin]
                ))
            }
        }
        return groups
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 0) {
                    if store.isLoading {
                        ProgressView()
                            .frame(maxWidth: .infinity, minHeight: 120)
                    } else if store.pins.isEmpty {
                        emptyState
                    } else {
                        timelineContent
                    }
                }
                .padding(.bottom, 104)
            }
            .scrollIndicators(.hidden)
            .navigationTitle("履歴")
            .navigationBarTitleDisplayMode(.large)
        }
        .onAppear {
            store.send(.onAppear)
        }
        .sheet(item: $store.scope(state: \.detail, action: \.detail)) { detailStore in
            PinDetailView(store: detailStore)
                .preferredColorScheme(colorSchemePreference.colorScheme)
        }
    }

    // MARK: - Timeline Content

    @ViewBuilder
    private var timelineContent: some View {
        let groups = groupedPins
        ForEach(Array(groups.enumerated()), id: \.element.date) { gi, group in
            let isLastGroup = gi == groups.count - 1
            DateSectionHeader(
                label: group.dateLabel,
                showTopLine: gi > 0,
                timelineColumnWidth: timelineColumnWidth
            )
            ForEach(Array(group.pins.enumerated()), id: \.element.id) { ei, pin in
                let isLastItem = isLastGroup && ei == group.pins.count - 1
                Button {
                    store.send(.pinTapped(pin))
                } label: {
                    HistoryRowView(
                        pin: pin,
                        showBottomLine: !isLastItem,
                        rowHalfHeight: rowHalfHeight,
                        timelineColumnWidth: timelineColumnWidth
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "clock")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)
            Text("まだピンがありません")
                .font(.headline)
                .foregroundStyle(.secondary)
            Text("ピンを追加すると、ここに履歴が表示されます")
                .font(.subheadline)
                .foregroundStyle(.tertiary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, minHeight: 240)
        .padding(.horizontal, 32)
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
    let pin: Pin
    let showBottomLine: Bool
    let rowHalfHeight: CGFloat
    let timelineColumnWidth: CGFloat

    private var timeString: String {
        let f = DateFormatter()
        f.dateFormat = "HH:mm"
        return f.string(from: pin.createdAt)
    }

    var body: some View {
        HStack(alignment: .center, spacing: 0) {
            HStack(spacing: 8) {
                Text(pin.title)
                    .font(.subheadline)
                    .lineLimit(1)
                    .frame(maxWidth: .infinity, alignment: .trailing)

                Image(systemName: pin.contentType.iconName)
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .frame(width: 20)

                Text(timeString)
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
        .accessibilityLabel("\(pin.title)、\(timeString)に追加")
    }
}

// MARK: - Preview

#Preview {
    HistoryView(store: Store(initialState: HistoryReducer.State()) {
        HistoryReducer()
    } withDependencies: {
        $0.pinClient.fetchAll = { [] }
    })
}
