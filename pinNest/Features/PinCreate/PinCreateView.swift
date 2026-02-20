import SwiftUI

struct PinCreateView: View {
    let contentType: PinContentType
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Image(systemName: contentType.iconName)
                    .font(.system(size: 56))
                    .foregroundStyle(Color.accentColor)
                Text("\(contentType.label)を追加")
                    .font(.title2.weight(.semibold))
                Text("（実装予定）")
                    .font(.body)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .navigationTitle("ピンを作成")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("キャンセル") { dismiss() }
                }
            }
        }
    }
}

#Preview {
    PinCreateView(contentType: .url)
}
