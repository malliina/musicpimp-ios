import SwiftUI
import Combine

enum PlayerPage {
  case player, playlist
}

struct PlayerView: View {
  @StateObject private var vm: PlayerVM = PlayerVM()
  
  var body: some View {
    PlayerViewInternal(vm: vm)
  }
}

struct PlayerViewInternal<T>: View where T: PlayerVMLike {
  let log = LoggerFactory.shared.view(PlayerViewInternal.self)
  @ObservedObject var vm: T
  
  @State private var segment: PlayerPage = .player
  @State private var presentVolume: Bool = false
  @State private var presentSaved: Bool = false
  @State private var presentSave: Bool = false
  @State private var askOverwrite: Bool = false
  @State var playlist: Playlist = Playlist.empty
  @State var playbackPosition: Float = 0
  @State var isSeeking: Bool = false
  @State var seekEnded: Date = Date.now.addingTimeInterval(-1)

  var positionText: String { playbackPosition.description }
  var position: Duration { playbackPosition.seconds ?? Duration.Zero }
  
  let padding: CGFloat = 12
  
  var body: some View {
    VStack {
      Picker("Segment", selection: $segment) {
        Text("Player").tag(PlayerPage.player)
        Text("Playlist").tag(PlayerPage.playlist)
      }
      .pickerStyle(.segmented)
      switch segment {
      case .player:
        VStack {
          Image(uiImage: vm.cover)
            .resizable()
            .aspectRatio(contentMode: .fit)
            .padding(.vertical, 12)
          Text(vm.track?.title ?? "No track")
            .font(.system(size: 28))
          if let track = vm.track {
            Text(track.album)
              .font(.title3)
              .foregroundStyle(colors.subtitles)
            Text(track.artist)
              .font(.title2)
          }
          HStack {
            Text(position.description)
            Spacer()
            Text(vm.durationText)
          }
          .padding(.horizontal, padding)
          .padding(.top, 6)
          Slider(
            value: $playbackPosition,
            in: 0...vm.durationValue,
            onEditingChanged: { editing in
              seekEnded = Date.now
              isSeeking = editing
              if !editing {
                Task {
                  await vm.on(seek: position)
                }
              }
            }
          )
          .padding(.horizontal, padding)
        }
        .toolbar {
          ToolbarItem(placement: .topBarTrailing) {
            Button {
              presentVolume = true
            } label: {
              Image(systemName: "speaker.wave.3")
            }
          }
        }
        .sheet(isPresented: $presentVolume) {
          if #available(iOS 16.0, *) {
            VolumeView(vm: VolumeVM.shared)
              .presentationDetents([.fraction(0.3)])
          } else {
            NavigationView {
              VolumeView(vm: VolumeVM.shared)
            }
          }
        }
      case .playlist:
        List {
          ForEach(vm.tracks) { trackAndIdx in
            Button {
              Task {
                await vm.skip(to: trackAndIdx.idx)
              }
            } label: {
              TrackItem(track: trackAndIdx.track, isActive: trackAndIdx.idx == vm.playlist.index, progress: nil)
            }
            .swipeActions {
              Button(role: .destructive) {
                Task {
                  await vm.remove(index: trackAndIdx.idx)
                }
              } label: {
                Text("Delete")
              }
            }
            .listRowBackground(colors.background)
          }
          .onMove { set, int in
            Task {
              await vm.move(indexSet: set, to: int)
            }
          }
        }
        .listStyle(.plain)
        .background(colors.background)
        .toolbar {
          ToolbarItem(placement: .topBarLeading) {
            EditButton().disabled(vm.tracks.isEmpty)
          }
        }
        .toolbar {
          ToolbarItem(placement: .topBarLeading) {
            Button {
              presentSaved = true
            } label: {
              Image(systemName: "book")
            }
          }
        }
        .toolbar {
          ToolbarItem(placement: .topBarTrailing) {
            Button {
              if vm.activePlaylist == nil {
                presentSave = true
              } else {
                askOverwrite = true
              }
            } label: {
              Text("Save")
            }
          }
        }
        .sheet(isPresented: $presentSave) {
          NavigationView {
            SavePlaylistView { name in
              await vm.save(name: name)
              presentSave = false
            }
          }
        }
        .sheet(isPresented: $presentSaved) {
          NavigationView {
            SavedPlaylistsView(vm: vm)
          }
        }
        .confirmationDialog("Save", isPresented: $askOverwrite) {
          if let saved = vm.activePlaylist {
            Button {
              Task {
                await vm.save(saved: saved)
              }
            } label: {
              Text("Save Current")
            }
          }
          Button {
            presentSave = true
          } label: {
            Text("Create New")
          }
        }
      }
      PlaybackFooter(vm: PlaybackVM.shared)
    }
    .onChange(of: vm.track) { track in
      Task {
        await vm.on(track: track)
      }
    }
    .onReceive(vm.updates) { meta in
      let timeHasPassed = Date.now.timeIntervalSince(seekEnded) >= 1
      if !isSeeking && timeHasPassed {
        playbackPosition = meta.time?.secondsFloat ?? 0
      }
      Task {
        await vm.on(update: meta)
      }
    }
    .navigationTitle("PLAYER")
    .navigationBarTitleDisplayMode(.inline)
    .background(colors.background)
  }
}

struct PlayerPreview: PimpPreviewProvider, PreviewProvider {
  class PreviewVM: PlayerVMLike {
    var activePlaylist: SavedPlaylist? = nil
    var cover: UIImage = CoverService.defaultCover!
    
    static let playerState = PlayerMeta(track: PreviewLibrary.track1, state: .Playing, time: 13.seconds, volume: nil, playlist: Playlist(tracks: [PreviewLibrary.track1, PreviewLibrary.track2], index: 1))
    var state: PlayerMeta { PlayerPreview.PreviewVM.playerState }
    
    var savedPlaylists: Outcome<[SavedPlaylist]> = Outcome.Idle
    @Published var meta: PlayerMeta? = PlayerPreview.PreviewVM.playerState
    var updates: AnyPublisher<PlayerMeta, Never> { meta.publisher.eraseToAnyPublisher() }
    
    func on(update: PlayerMeta) async {}
    func on(track: Track?) async {}
    func on(seek to: Duration) async {}
    
    func loadPlaylists() async {}
    func save(name: String) async {}
    func deletePlaylist(id: PlaylistID) async {}
    
    func select(playlist: SavedPlaylist) async {}
    func save(saved: SavedPlaylist) async {}
    func skip(to: Int) async {}
    
    func remove(index: Int) async {}
    func move(indexSet: IndexSet, to: Int) async {}
  }
  static var preview: some View {
    NavigationView {
      PlayerViewInternal(vm: PreviewVM())
    }
  }
}
