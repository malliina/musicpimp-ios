import SwiftUI

func fullSizeText(_ text: String) -> some View {
  Text(text)
    .padding(.horizontal, 12)
    .frame(maxWidth: .infinity, maxHeight: .infinity)
}
