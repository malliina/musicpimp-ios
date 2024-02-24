import Foundation

class DetailedCell: PimpCell {

  override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
    super.init(style: .value1, reuseIdentifier: reuseIdentifier)
    initCell()
  }

  init(reuseIdentifier: String) {
    super.init(style: .value1, reuseIdentifier: reuseIdentifier)
    initCell()
  }

  required init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
    initCell()
  }

  func initCell() {
    detailTextLabel?.textColor = colors.titles
  }
}
