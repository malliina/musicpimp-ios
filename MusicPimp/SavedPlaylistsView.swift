import SwiftUI

struct SavedPlaylistsView<T>: View where T: PlayerVMLike {
  @Environment(\.dismiss) private var dismiss
  
  @ObservedObject var vm: T
  
  var body: some View {
    outcomeView(outcome: vm.savedPlaylists) { playlists in
      List {
        ForEach(playlists, id: \.name) { playlist in
          Button {
            Task {
              await vm.select(playlist: playlist)
              await controls.playChecked(playlist.tracks)
              dismiss()
            }
          } label: {
            ThreeLabelRow(label: playlist.name, subLeft: "\(playlist.trackCount) tracks", subRight: "\(playlist.duration.description)", track: nil)
          }
          .swipeActions {
            Button(role: .destructive) {
              Task {
                if let id = playlist.id {
                  await vm.deletePlaylist(id: id)
                }
              }
            } label: {
              Text("Delete")
            }
          }
          .listRowBackground(colors.background)
        }
      }
      .listStyle(.plain)
    }
    .task {
      await vm.loadPlaylists()
    }
    .navigationTitle("SELECT TO PLAY")
    .navigationBarTitleDisplayMode(.inline)
    .toolbar {
      ToolbarItem(placement: .topBarTrailing) {
        Button {
          dismiss()
        } label: {
          Text("Done")
        }
      }
    }
    .background(colors.background)
  }
}
