import PDFKit
import SwiftUI

struct PDFViewerView: View {
    let url: URL
    let title: String

    var body: some View {
        MediaViewerView(title: title, darkToolbar: false) {
            PDFKitView(url: url)
                .ignoresSafeArea(edges: .bottom)
        }
    }
}

// MARK: - PDFKitView

private struct PDFKitView: UIViewRepresentable {
    let url: URL

    func makeUIView(context: Context) -> PDFView {
        let pdfView = PDFView()
        pdfView.autoScales = true
        pdfView.displayMode = .singlePageContinuous
        pdfView.displayDirection = .vertical
        pdfView.usePageViewController(false)
        pdfView.document = PDFDocument(url: url)
        return pdfView
    }

    func updateUIView(_ uiView: PDFView, context: Context) {}
}
