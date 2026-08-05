import UIKit
import AppDimens
import AppDimensUI

final class CardViewController: UIViewController {
    private let spacing = 16.dynamic.when(.minShortestSide(600), 24).limits(min: 12, max: 32)
    private let stack = UIStackView()

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        stack.spacing = spacing.points(in: .current(for: view))
    }
}
