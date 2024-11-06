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
    faIcon(name: name)
  }
}

func faIcon(name: String) -> some View {
  Text(String.fontAwesomeIconStringForIconIdentifier(name))
    .font(Font(UIFont(awesomeFontOfSize: 24)))
}

@ViewBuilder
func outcomeView<T, A>(outcome: Outcome<T>, @ViewBuilder render: (T) -> A) -> some View where A: View {
  switch outcome {
  case .Idle:
    fullSizeText("")
  case .Loading:
    ProgressView()
      .frame(maxWidth: .infinity, maxHeight: .infinity)
  case .Loaded(let t):
    render(t)
  case .Err(let error):
    fullSizeText("Error. \(error)")
  }
}
