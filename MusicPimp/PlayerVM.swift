import Combine

struct TrackAndIdx: Identifiable {
  let track: Track
  let idx: Int
  var id: String { "\(track.idStr)-\(idx)" }
}

protocol PlayerVMLike: ObservableObject {
  var state: PlayerMeta { get }
  var playlist: Playlist { get }
  var tracks: [TrackAndIdx] { get }
  var activePlaylist: SavedPlaylist? { get }
  var savedPlaylists: Outcome<[SavedPlaylist]> { get }
  var updates: AnyPublisher<PlayerMeta, Never> { get }
  var cover: UIImage { get }
  func on(update: PlayerMeta) async
  func on(track: Track?) async
  func on(seek to: Duration) async
  
  func loadPlaylists() async
  func save(name: String) async
  func deletePlaylist(id: PlaylistID) async
  func skip(to: Int) async
  func save(saved: SavedPlaylist) async
  func select(playlist: SavedPlaylist) async
  func remove(index: Int) async
  func move(indexSet: IndexSet, to: Int) async
}

extension PlayerVMLike {
  var track: Track? { state.track }
  var duration: Duration { track?.duration ?? Duration.Zero }
  var durationValue: Float { duration.secondsFloat }
  var durationText: String { duration.description }
  var playlist: Playlist { state.playlist ?? Playlist.empty }
  var tracks: [TrackAndIdx] { playlist.tracks.enumerated().map { (idx, t) in
    TrackAndIdx(track: t, idx: idx)
  } }
}

class PlayerVM: PlayerVMLike {
  let log = LoggerFactory.shared.vc(PlayerVM.self)
  
  @Published var state: PlayerMeta
  @Published var savedPlaylists: Outcome<[SavedPlaylist]> = Outcome.Idle
  @Published var activePlaylist: SavedPlaylist? = nil
  @Published var cover: UIImage = CoverService.defaultCover!

  var updates: AnyPublisher<PlayerMeta, Never> {
    playerManager.$playerChanged.flatMap { player in
      return player.updates
    }.receive(on: DispatchQueue.main).removeDuplicates().eraseToAnyPublisher()
  }
  var trackUpdates: AnyPublisher<Track?, Never> {
    playerManager.$playerChanged.flatMap { player in
      return player.trackEvent
    }.receive(on: DispatchQueue.main).removeDuplicates().eraseToAnyPublisher()
  }
  var timeUpdates: AnyPublisher<Duration?, Never> {
    playerManager.$playerChanged.flatMap { player in
      return player.timeEvent
    }.receive(on: DispatchQueue.main).removeDuplicates().eraseToAnyPublisher()
  }
  var volumeUpdates: AnyPublisher<VolumeValue?, Never> {
    playerManager.$playerChanged.flatMap { player in
      return player.volumeEvent
    }.receive(on: DispatchQueue.main).removeDuplicates().eraseToAnyPublisher()
  }
  var stateUpdates: AnyPublisher<PlaybackState?, Never> {
    playerManager.$playerChanged.flatMap { player in
      return player.stateEvent
    }.receive(on: DispatchQueue.main).removeDuplicates().eraseToAnyPublisher()
  }
  var playlistIndexUpdates: AnyPublisher<Int?, Never> {
    playerManager.$playerChanged.flatMap { player in
      return player.playlist.indexPublisher
    }.receive(on: DispatchQueue.main).removeDuplicates().eraseToAnyPublisher()
  }
  var playlistUpdates: AnyPublisher<Playlist?, Never> {
    playerManager.$playerChanged.flatMap { player in
      return player.playlist.playlistPublisher
    }.receive(on: DispatchQueue.main).removeDuplicates().eraseToAnyPublisher()
  }
  
  private var cancellables: [Task<(), Never>] = []
  
  init() {
    state = PlayerMeta.empty
    let c2 = Task {
      for await time in timeUpdates.values {
        await on(time: time)
      }
    }
    let c3 = Task {
      for await t in trackUpdates.values {
        await on(song: t)
      }
    }
    let c4 = Task {
      for await volume in volumeUpdates.values {
        await on(volume: volume)
      }
    }
    let c5 = Task {
      for await newState in stateUpdates.values {
        await on(playState: newState)
      }
    }
    let c6 = Task {
      for await newList in playlistUpdates.values {
        await on(playlist: newList)
      }
    }
    let c7 = Task {
      for await idx in playlistIndexUpdates.values {
        await on(playlistIndex: idx)
      }
    }
    cancellables = [c2, c3, c4, c5, c6, c7]
  }
  
  @MainActor
  func on(time: Duration?) async {
    await on(update: PlayerMeta(track: state.track, state: state.state, time: time, volume: state.volume, playlist: state.playlist))
  }
  @MainActor
  func on(volume: VolumeValue?) async {
    await on(update: PlayerMeta(track: state.track, state: state.state, time: state.time, volume: volume, playlist: state.playlist))
  }
  @MainActor
  func on(playlist: Playlist?) async {
    await on(update: PlayerMeta(track: state.track, state: state.state, time: state.time, volume: state.volume, playlist: playlist))
  }
  @MainActor
  func on(playlistIndex: Int?) async {
    if let list = state.playlist {
      await on(update: PlayerMeta(track: state.track, state: state.state, time: state.time, volume: state.volume, playlist: Playlist(tracks: list.tracks, index: playlistIndex)))
    }
  }
  @MainActor
  func on(song: Track?) async {
    await on(update: PlayerMeta(track: song, state: state.state, time: state.time, volume: state.volume, playlist: state.playlist))
  }
  @MainActor
  func on(playState: PlaybackState?) async {
    await on(update: PlayerMeta(track: state.track, state: playState, time: state.time, volume: state.volume, playlist: state.playlist))
  }
  
  @MainActor
  func on(update: PlayerMeta) async {
    //log.info("State update to \(update) from \(state)")
    if update != state {
      self.state = update
    } else {
      //log.info("Identical state, doing nothing.")
    }
  }
  
  func skip(to: Int) async {
    let _ = await player.skip(to)
  }
  
  func move(indexSet: IndexSet, to: Int) async {
    if let src = indexSet.first, src != to {
      let dest = to < src ? to : to - 1
      log.info("Moving \(src) to \(dest)...")
      let _ = await player.playlist.move(src, dest: dest)
    }
  }
  
  @MainActor
  func select(playlist: SavedPlaylist) async {
    self.activePlaylist = playlist
  }
  
  func on(seek to: Duration) async {
    log.info("Seeking to \(to)...")
    let _ = await player.seek(to)
  }
  
  func on(track: Track?) async {
    var image = CoverService.defaultCover!
    if let track = track {
      let result = await CoverService.sharedInstance.cover(track.artist, album: track.album)
      if let imageResult = result.image, player.current().track?.title == track.title {
        image = imageResult
      }
    }
    await update(cover: image)
  }
  
  @MainActor
  private func update(cover: UIImage) {
    self.cover = cover
  }
  
  func loadPlaylists() async {
    await update(saveds: .Loading)
    do {
      let ps = try await library.playlists()
      await update(saveds: .Loaded(data: ps))
    } catch {
      await update(saveds: .Err(error: error))
    }
  }
  
  func save(name: String) async {
    await save(playlist: SavedPlaylist.from(id: nil, name: name, tracks: playlist.tracks))
  }
  
  func save(saved: SavedPlaylist) async {
    let list = SavedPlaylist.from(id: saved.id, name: saved.name, tracks: playlist.tracks)
    await save(playlist: list)
  }
  
  func remove(index: Int) async {
    let _ = await player.playlist.removeIndex(index)
  }
  
  private func save(playlist: SavedPlaylist) async {
    do {
      let id = try await library.savePlaylist(playlist)
      log.info("Saved playlist with name \(playlist.name) and ID \(id).")
    } catch {
      log.error("Failed to save playlist. \(error)")
    }
  }
  
  func deletePlaylist(id: PlaylistID) async {
    do {
      let _ = try await library.deletePlaylist(id)
      let ps = try await library.playlists()
      await update(saveds: .Loaded(data: ps))
    } catch {
      log.info("Failed to delete playlist \(id). \(error)")
    }
  }
  
  @MainActor private func update(saveds: Outcome<[SavedPlaylist]>) {
    self.savedPlaylists = saveds
  }
}
