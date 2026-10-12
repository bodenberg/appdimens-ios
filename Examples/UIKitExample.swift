import UIKit
import AppDimensDynamic

final class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?
    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options: UIScene.ConnectionOptions) {
        AppDimens.startAutomaticUpdates()            // keeps 16.sdp in sync with the key window
    }
}

final class ProfileViewController: UIViewController {
    private let titleLabel = UILabel()
    private var observation: AppDimensObservation?

    override func viewDidLoad() {
        super.viewDidLoad()
        view.addSubview(titleLabel)
        applyDimensions()
        observation = AppDimens.observe { [weak self] _ in
            DispatchQueue.main.async { self?.applyDimensions() }   // rotation, Split View, Dynamic Type
        }
    }

    private func applyDimensions() {
        titleLabel.font = .ssp(20, weight: .semibold)
        view.layoutMargins = UIEdgeInsets(top: 16.sdp, left: 16.sdp, bottom: 16.sdp, right: 16.sdp)
        view.layer.cornerRadius = 30.sdpMode(12, .car)   // 30 by default, 12 on CarPlay
    }
}
