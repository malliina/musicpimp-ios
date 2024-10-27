import SwiftUI

class PimpPreviews {
  static let shared = PimpPreviews()
  
  let devices = ["iPhone 13 mini", "iPad Pro (11-inch) (4th generation)"]
}

protocol PimpPreviewProvider: PreviewProvider {
  associatedtype Preview: View
  static var preview: Preview { get }
}

extension PimpPreviewProvider {
  static var previews: some View {
    ForEach(PimpPreviews.shared.devices, id: \.self) { deviceName in
      Group {
        preview
      }
      .preferredColorScheme(.dark)
      .previewDevice(PreviewDevice(rawValue: deviceName))
      .previewDisplayName(deviceName)
    }
  }
}
