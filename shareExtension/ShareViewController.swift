import ComposableArchitecture
import SwiftUI
import UIKit

/// Share Extension のエントリポイント。
/// extensionContext から NSItemProvider を取得し、TCA Store + SwiftUI で UI を表示する。
final class ShareViewController: UIViewController {

    private var store: StoreOf<ShareReducer>?

    override func viewDidLoad() {
        super.viewDidLoad()

        // extensionContext から NSItemProvider を取得
        guard let extensionItem = extensionContext?.inputItems.first as? NSExtensionItem,
              let attachments = extensionItem.attachments,
              !attachments.isEmpty else {
            extensionContext?.cancelRequest(withError: ShareExtensionError.noContent)
            return
        }

        // TCA Store を生成
        let store = Store(initialState: ShareReducer.State()) {
            ShareReducer()
        }
        self.store = store

        // SwiftUI View を UIHostingController でホスト
        let shareView = ShareView(
            store: store,
            onComplete: { [weak self] in
                self?.extensionContext?.completeRequest(returningItems: nil)
            },
            onCancel: { [weak self] in
                let error = NSError(
                    domain: "com.noricoffee.pinNest.shareextension",
                    code: NSUserCancelledError,
                    userInfo: [NSLocalizedDescriptionKey: "ユーザーがキャンセルしました"]
                )
                self?.extensionContext?.cancelRequest(withError: error)
            }
        )

        let hostVC = UIHostingController(rootView: shareView)
        addChild(hostVC)
        hostVC.view.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(hostVC.view)
        NSLayoutConstraint.activate([
            hostVC.view.topAnchor.constraint(equalTo: view.topAnchor),
            hostVC.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            hostVC.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            hostVC.view.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
        hostVC.didMove(toParent: self)

        // コンテンツの読み込みを開始
        store.send(.loadContent(attachments))
    }
}
