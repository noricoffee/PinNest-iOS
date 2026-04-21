import ComposableArchitecture
import SwiftUI
import UIKit

// MARK: - HistoryView

struct HistoryView: View {
    @Bindable var store: StoreOf<HistoryReducer>
    @Environment(\.colorSchemePreference) private var colorSchemePreference

    private let timelineColumnWidth: CGFloat = 20

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
        .sheet(item: $store.scope(state: \.contextMenu.tagPicker, action: \.contextMenu.tagPicker)) { pickerStore in
            TagPickerView(store: pickerStore)
                .preferredColorScheme(colorSchemePreference.colorScheme)
        }
        .alert(
            "ピンを削除しますか？",
            isPresented: Binding(
                get: { store.contextMenu.isDeleteAlertPresented },
                set: { if !$0 { store.send(.contextMenu(.deleteAlertDismissed)) } }
            )
        ) {
            Button("削除", role: .destructive) {
                store.send(.contextMenu(.deleteConfirmed))
            }
            Button("キャンセル", role: .cancel) {
                store.send(.contextMenu(.deleteAlertDismissed))
            }
        } message: {
            Text("この操作は取り消せません。")
        }
        .sheet(
            isPresented: Binding(
                get: { store.contextMenu.isShareSheetPresented },
                set: { if !$0 { store.send(.contextMenu(.shareSheetDismissed)) } }
            )
        ) {
            ShareSheet(items: store.contextMenu.shareItems)
                .presentationDetents([.medium, .large])
        }
        .alert(
            "読み込みエラー",
            isPresented: Binding(
                get: { store.errorMessage != nil },
                set: { if !$0 { store.send(.errorAlertDismissed) } }
            )
        ) {
            Button("OK", role: .cancel) {
                store.send(.errorAlertDismissed)
            }
        } message: {
            Text(store.errorMessage ?? "")
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
            .padding(.top, gi > 0 ? 24 : 0)
            ForEach(Array(group.pins.enumerated()), id: \.element.id) { ei, pin in
                let isLastItem = isLastGroup && ei == group.pins.count - 1
                HistoryRowView(
                    pin: pin,
                    showBottomLine: !isLastItem,
                    timelineColumnWidth: timelineColumnWidth,
                    onTap: { store.send(.pinTapped(pin)) },
                    menuActions: PinMenuAction.actions(
                        contentType: pin.contentType,
                        onOpenLink: { store.send(.contextMenu(.openLinkTapped(pin))) },
                        onCopyLink: { store.send(.contextMenu(.copyLinkTapped(pin))) },
                        onCopyBody: { store.send(.contextMenu(.copyBodyTapped(pin))) },
                        onShare: { store.send(.contextMenu(.shareTapped(pin))) },
                        onAddTag: { store.send(.contextMenu(.addTagTapped(pin))) },
                        onDelete: { store.send(.contextMenu(.deleteTapped(pin))) }
                    )
                )
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

// MARK: - DateSectionHeader（元のまま）

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
    let timelineColumnWidth: CGFloat
    let onTap: () -> Void
    let menuActions: [PinMenuAction]

    var body: some View {
        HStack(alignment: .top, spacing: 0) {
            // カード（左側・可変幅）
            Button { onTap() } label: {
                HistoryRowCard(pin: pin)
                    .pinContextMenu(menuActions)
            }
            .buttonStyle(.plain)
            .frame(maxWidth: .infinity)
            .padding(.trailing, 12)

            // ピンアイコン + 縦線（右端・固定幅）
            VStack(spacing: 0) {
                Image(systemName: "pin.fill")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Color.accentColor)
                    .rotationEffect(.degrees(45))

                if showBottomLine {
                    Rectangle()
                        .fill(Color(.separator))
                        .frame(width: 1)
                        .frame(maxHeight: .infinity)
                } else {
                    Color.clear
                        .frame(maxHeight: .infinity)
                }
            }
            .frame(width: timelineColumnWidth)
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 16)
        .accessibilityLabel("\(pin.title)、\(pin.createdAt.formatted(date: .omitted, time: .shortened))に追加")
    }
}

// MARK: - HistoryRowCard

private struct HistoryRowCard: View {
    let pin: Pin

    private var timeString: String {
        let f = DateFormatter()
        f.dateFormat = "HH:mm"
        return f.string(from: pin.createdAt)
    }

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            if pin.contentType != .text {
                ThumbnailSquare(pin: pin)
                    .frame(width: 56, height: 56)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
            }

            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text(pin.title)
                    .font(.subheadline.weight(.medium))
                    .lineLimit(2)
                    .frame(maxWidth: .infinity, alignment: .leading)
                Text(timeString)
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}

// MARK: - ThumbnailSquare

private struct ThumbnailSquare: View {
    let pin: Pin

    var body: some View {
        switch pin.contentType {
        case .url:
            urlThumbnail
        case .image:
            imageThumbnail
        case .video:
            videoThumbnail
        case .pdf:
            pdfThumbnail
        case .text:
            textThumbnail
        }
    }

    @ViewBuilder
    private var urlThumbnail: some View {
        if let filePath = pin.filePath,
           let uiImage = UIImage(contentsOfFile: ThumbnailCache.resolveAbsolutePath(filePath)) {
            Image(uiImage: uiImage)
                .resizable()
                .scaledToFill()
        } else {
            pin.contentType.displayColor
                .overlay {
                    Image(systemName: "globe")
                        .font(.title3)
                        .foregroundStyle(.white)
                }
        }
    }

    @ViewBuilder
    private var imageThumbnail: some View {
        if let filePath = pin.filePath,
           let uiImage = UIImage(contentsOfFile: ThumbnailCache.resolveAbsolutePath(filePath)) {
            Image(uiImage: uiImage)
                .resizable()
                .scaledToFill()
        } else {
            pin.contentType.displayColor
                .overlay {
                    Image(systemName: "photo.fill")
                        .font(.title3)
                        .foregroundStyle(.white)
                }
        }
    }

    @ViewBuilder
    private var videoThumbnail: some View {
        if let thumbnail = ThumbnailCache.loadThumbnail(for: pin.id) {
            ZStack {
                Image(uiImage: thumbnail)
                    .resizable()
                    .scaledToFill()
                Image(systemName: "play.circle.fill")
                    .font(.title2)
                    .foregroundStyle(.white)
                    .shadow(color: .black.opacity(0.4), radius: 4)
            }
        } else {
            pin.contentType.displayColor
                .overlay {
                    Image(systemName: "play.circle.fill")
                        .font(.title3)
                        .foregroundStyle(.white)
                }
        }
    }

    @ViewBuilder
    private var pdfThumbnail: some View {
        if let thumbnail = ThumbnailCache.loadThumbnail(for: pin.id) {
            Image(uiImage: thumbnail)
                .resizable()
                .scaledToFill()
        } else {
            Color(.tertiarySystemBackground)
                .overlay {
                    Image(systemName: "doc.richtext.fill")
                        .font(.title3)
                        .foregroundStyle(.red)
                }
        }
    }

    private var textThumbnail: some View {
        pin.contentType.displayColor
            .overlay {
                Image(systemName: "text.alignleft")
                    .font(.title3)
                    .foregroundStyle(.white)
            }
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
