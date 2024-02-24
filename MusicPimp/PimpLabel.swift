import Foundation

class PimpLabel: UILabel {
  static let headerTopMargin: CGFloat = 16

  static func footerLabel(_ text: String) -> UILabel {
    let label = create(fontSize: 16)
    label.text = text
    label.lineBreakMode = .byWordWrapping
    label.numberOfLines = 0
    label.sizeToFit()
    return label
  }

  static func create(
    textColor: UIColor = PimpColors.shared.titles, fontSize: CGFloat = UIFont.labelFontSize
  ) -> UILabel {
    let label = UILabel()
    label.textColor = textColor
    label.font = label.font.withSize(fontSize)
    return label
  }

  static func centered(text: String) -> UILabel {
    let label = create()
    label.text = text
    label.numberOfLines = 0
    label.lineBreakMode = .byWordWrapping
    label.textAlignment = .center
    return label
  }
}

extension UILabel {
  func tableHeaderHeight(_ tableView: UITableView) -> CGFloat {
    let availableWidth =
      tableView.frame.width - (tableView.layoutMargins.left) - (tableView.layoutMargins.right)
    return self.sizeThatFits(CGSize(width: availableWidth, height: CGFloat.greatestFiniteMagnitude))
      .height + PimpLabel.headerTopMargin
  }
}
