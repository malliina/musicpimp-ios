import Foundation

class PimpCell: UITableViewCell {
  let colors = PimpColors.shared

  override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
    super.init(style: style, reuseIdentifier: reuseIdentifier)
    configureView()
  }

  required init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
    configureView()
  }

  func configureView() {
    textLabel?.textColor = PimpColors.shared.titles
  }
}
