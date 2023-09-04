
import Foundation

class FeedbackLabel: UILabel {
    override func drawText(in rect: CGRect) {
        let insets: UIEdgeInsets = UIEdgeInsets(top: 0.0, left: 8.0, bottom: 0.0, right: 8.0)
        super.drawText(in: rect.inset(by: insets))
    }
}
