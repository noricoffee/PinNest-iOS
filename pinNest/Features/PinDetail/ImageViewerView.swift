import SwiftUI
import UIKit

struct ImageViewerView: View {
    let uiImage: UIImage

    var body: some View {
        MediaViewerView {
            Color.black
                .ignoresSafeArea()
                .overlay {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFit()
                }
        }
    }
}
