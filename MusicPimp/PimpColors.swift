import Foundation
import SwiftUI

class PimpColors {
  static let shared = PimpColors()

  let white = Colors.rgb(244, green: 244, blue: 244)
  var text: UIColor { white }
  let background = Colors.rgb(2, green: 23, blue: 42)
  let header = Colors.rgb(23, green: 46, blue: 84)
  let lighterBackground = Colors.rgb(3, green: 32, blue: 52)
  var titles: UIColor { white }
  let separator = Colors.rgb(255, green: 255, blue: 255, alpha: 0.2)
  let notSelected = Colors.rgb(161, green: 161, blue: 161)
  var subtitles: UIColor { notSelected }
  let selected = Colors.rgb(36, green: 131, blue: 233)
  var selectedBackground: UIColor { selected }
  //    let tintColor = UIColor.greenColor()
  var tintColor: UIColor { selected }
  // used by tabbar, navigationbar
  let barStyle = UIBarStyle.black
  let deletion = UIColor.red
  let deletionHighlighted = Colors.rgb(139, green: 0, blue: 0)
  var placeholder: UIColor { separator }
  let titleFont = UIFont.boldSystemFont(ofSize: 13)
}

class MusicColors {
  static let shared = MusicColors(PimpColors.shared)

  let ref: PimpColors
  init(_ ref: PimpColors) {
    self.ref = ref
  }

  var background: Color { Color(uiColor: ref.background) }
  var titles: Color { Color(uiColor: ref.titles) }
  var subtitles: Color { Color(uiColor: ref.subtitles) }
}

extension View {
  var colors: MusicColors { MusicColors.shared }
}

extension UIViewController {
  var colors: PimpColors { PimpColors.shared }
}
