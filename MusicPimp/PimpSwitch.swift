import Foundation

// UISwitch that hides the crazy addTarget API
class PimpSwitch: UISwitch {
  let onClick: (UISwitch) -> Void

  init(onClick: @escaping (UISwitch) -> Void) {
    self.onClick = onClick
    super.init(frame: CGRect.zero)
    addTarget(nil, action: #selector(runOnClick(_:)), for: UIControl.Event.valueChanged)
  }

  required init?(coder aDecoder: NSCoder) {
    self.onClick = { (s) -> Void in () }
    super.init(coder: aDecoder)
  }

  @objc fileprivate func runOnClick(_ uiSwitch: UISwitch) {
    onClick(uiSwitch)
  }
}
