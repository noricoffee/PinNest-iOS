import SwiftUI

struct SearchView: View {
    var body: some View {
        NavigationStack {
            Text("検索")
                .foregroundStyle(.secondary)
                .navigationTitle("検索")
                .navigationBarTitleDisplayMode(.large)
        }
    }
}

#Preview {
    SearchView()
}
