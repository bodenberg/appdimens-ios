import UIKit
import AppDimensUI

@MainActor
func configure(_ view: UIView, label: UILabel) {
    let context = DimensContext.current(in: view)
    let inset = CGFloat(16.sdp(in: context))
    view.directionalLayoutMargins = NSDirectionalEdgeInsets(top: inset, leading: inset, bottom: inset, trailing: inset)
    label.font = UIFont.systemFont(ofSize: inset).appDimensScaled()
}
