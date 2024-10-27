import SwiftUI

func fullSizeText(_ text: String) -> some View {
  Text(text)
    .padding(.horizontal, 12)
    .frame(maxWidth: .infinity, maxHeight: .infinity)
}

@ViewBuilder
func faButton(name: String, action: @escaping () async -> ()) -> some View {
  Button {
    Task {
      await action()
    }
  } label: {
    Text(String.fontAwesomeIconStringForIconIdentifier(name))
      .font(Font(UIFont(awesomeFontOfSize: 24)))
  }
}
