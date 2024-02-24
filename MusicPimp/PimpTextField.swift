import Foundation

class PimpTextField: UITextField, UITextFieldDelegate {
  let colors = PimpColors.shared

  var placeholderText: String? {
    get { return placeholder }
    set(newPlaceholder) {
      attributedPlaceholder = NSAttributedString(
        string: newPlaceholder ?? "",
        attributes: [NSAttributedString.Key.foregroundColor: PimpColors.shared.placeholder])
    }
  }

  override init(frame: CGRect) {
    super.init(frame: frame)
    pimpInit()
  }

  required init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
    pimpInit()
  }

  fileprivate func pimpInit() {
    delegate = self
    autocorrectionType = .no
    backgroundColor = colors.lighterBackground
    textColor = colors.titles
    borderStyle = .roundedRect
    autocapitalizationType = .none
  }

  func textFieldShouldReturn(_ textField: UITextField) -> Bool {
    textField.resignFirstResponder()
    return true
  }
}
