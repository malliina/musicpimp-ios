import Foundation

class SnapMainSubCell: MainSubCell {
  override func layoutSubviews() {
    super.layoutSubviews()
    super.removeAccessoryMargin()
  }
}
