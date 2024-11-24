import SwiftUI

func fullSizeText(_ text: String) -> some View {
  Text(text)
    .padding(.horizontal, 12)
    .frame(maxWidth: .infinity, maxHeight: .infinity)
}

func subtitle(_ text: String) -> some View {
  Text(text)
    .foregroundColor(MusicColors.shared.subtitles)
    .font(.system(size: 15))
}

func textField(_ placeholder: String, text: Binding<String>) -> some View {
  TextField(placeholder, text: text)
    .padding(6)
    .background(MusicColors.shared.lighterBackground)
}

struct PimpTextFieldModifier: ViewModifier {
  func body(content: Content) -> some View {
    content
      .padding(6)
      .background(MusicColors.shared.lighterBackground)
  }
}

extension View {
  func pimpTextField() -> some View {
    modifier(PimpTextFieldModifier())
  }
}

struct PimpTextFieldStyle: TextFieldStyle {
  func _body(configuration: TextField<Self._Label>) -> some View {
    configuration
      .pimpTextField()
      .textInputAutocapitalization(.never)
  }
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
