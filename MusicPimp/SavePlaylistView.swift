import SwiftUI

struct SavePlaylistView: View {
  @State var name: String = ""
  @FocusState private var nameFieldFocused: Bool
  
  var canSave: Bool { !name.isEmpty }
  
  let onSave: (String) async -> ()
  
  var body: some View {
    VStack {
      Text("Playlist Name")
      TextField("Name here", text: $name)
        .focused($nameFieldFocused)
        .pimpTextField()
    }
    .padding()
    .navigationTitle("NEW PLAYLIST")
    .navigationBarTitleDisplayMode(.inline)
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(colors.background)
    .colorScheme(.dark)
    .toolbar {
      ToolbarItem(placement: .topBarTrailing) {
        Button("Save") {
          Task {
            await onSave(name)
          }
        }.disabled(!canSave)
      }
    }
    .onAppear {
      nameFieldFocused = true
    }
  }
}

struct SavePlaylistPreviews: PimpPreviewProvider, PreviewProvider {
  static var preview: some View {
    SavePlaylistView { name in
      
    }
  }
}
