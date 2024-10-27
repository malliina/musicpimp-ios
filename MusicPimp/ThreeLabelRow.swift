import SwiftUI

struct ThreeLabelRow: View {
  let label: String
  let subLeft: String
  let subRight: String
  let track: Track?
  @State private var isAction = false
  
  var body: some View {
    HStack(spacing: 12) {
      VStack(alignment: .leading, spacing: 6) {
        Text(label)
        HStack(spacing: 6) {
          subtitle(subLeft)
          Spacer()
          subtitle(subRight)
        }
      }
      if let track = track {
        Button {
          isAction = true
        } label: {
          Image(systemName: "ellipsis")
            .tint(.gray)
        }
        .musicConfirmationDialog(isPresented: $isAction, track: track)
      }
    }
  }
  
  private func subtitle(_ text: String) -> some View {
    Text(text)
      .foregroundColor(colors.subtitles)
      .font(.system(size: 15))
  }
}

struct ThreeLabelRowPreviews: PimpPreviewProvider, PreviewProvider {
  static var preview: some View {
    List {
      ThreeLabelRow(label: "Track 1", subLeft: "Artist 1", subRight: "Nice 1", track: PreviewLibrary.track1)
      ThreeLabelRow(label: "Track 2", subLeft: "Artist 2", subRight: "Nice 2", track: nil)
    }.listStyle(.plain)
  }
}
