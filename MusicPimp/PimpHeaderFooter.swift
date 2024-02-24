import Foundation

class PimpHeaderFooter {
  static func withText(_ text: String) -> UITableViewHeaderFooterView {
    let view = UITableViewHeaderFooterView()
    view.contentView.backgroundColor = PimpColors.shared.lighterBackground
    if let label = view.textLabel {
      label.text = text
    }
    return view
  }
}
