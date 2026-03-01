import AVKit
import SwiftUI

struct VideoPlayerView: View {
    let url: URL

    var body: some View {
        MediaViewerView {
            AVPlayerViewControllerRepresentable(url: url)
                .ignoresSafeArea()
        }
    }
}

// MARK: - AVPlayerViewControllerRepresentable

private struct AVPlayerViewControllerRepresentable: UIViewControllerRepresentable {
    let url: URL

    func makeUIViewController(context: Context) -> AVPlayerViewController {
        let controller = AVPlayerViewController()
        controller.player = AVPlayer(url: url)
        controller.player?.play()
        return controller
    }

    func updateUIViewController(_ uiViewController: AVPlayerViewController, context: Context) {}
}
