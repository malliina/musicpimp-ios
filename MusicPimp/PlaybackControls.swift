protocol Playbacks {
  func play(_ item: MusicItem) async
  func add(_ item: MusicItem) async
  func download(_ item: MusicItem) async
}

class PlaybackControls: Playbacks {
  static let shared = PlaybackControls()
  
  let log = LoggerFactory.shared.pimp(PlaybackVM.self)
  
  let maxNewDownloads = 300
  let settings = PimpSettings.sharedInstance
  var libraryManager: LibraryManager { LibraryManager.sharedInstance }
  var library: LibraryType { libraryManager.libraryUpdated }
  var playerManager: PlayerManager { PlayerManager.sharedInstance }
  var player: PlayerType { playerManager.playerChanged }
  
  var isLocalLibrary: Bool { library.isLocal }
  var premium: PremiumState { PremiumState.shared }
  
  func play(_ item: MusicItem) async {
    let _ = await premium.limitChecked {
      let ts = await fetchTracks(item: item)
      let _ = await self.playTracks(ts)
    }
  }
  func add(_ item: MusicItem) async {
    let _ = await premium.limitChecked {
      let ts = await fetchTracks(item: item)
      let _ = await addTracks(ts)
    }
  }
  func download(_ item: MusicItem) async {
    let _ = await premium.limitChecked {
      let ts = await fetchTracks(item: item)
      let _ = downloadIfNeeded(ts)
    }
  }
  
  private func fetchTracks(item: MusicItem) async -> [Track] {
    do {
      return if let folder = item as? Folder {
        try await library.tracks(folder.id)
      } else if let track = item as? Track {
        [track]
      } else {
        []
      }
    } catch {
      log.error("Failed to fetch tracks of item \(item.idStr). \(error)")
      return []
    }
  }
  
  private func playAndDownload(_ track: Track) async -> ErrorMessage? {
    let error = await player.resetAndPlay(tracks: [track])
    if error == nil {
      return downloadIfNeeded([track]).headOption()
    } else {
      return error
    }
  }
  
  private func playTracks(_ tracks: [Track]) async -> [ErrorMessage] {
    let playResult = await player.resetAndPlay(tracks: tracks)
    let downloadResult = downloadIfNeeded(tracks.take(3))
    let result = playResult.map { [$0] } ?? []
    return downloadResult + result
  }
  
  private func addTracks(_ tracks: [Track]) async -> [ErrorMessage] {
    if !tracks.isEmpty {
      let errors = await player.playlist.add(tracks)
      if errors.isEmpty {
        return downloadIfNeeded(tracks.take(3))
      } else {
        return errors
      }
    } else {
      return []
    }
  }
  
  private func downloadIfNeeded(_ tracks: [Track]) -> [ErrorMessage] {
    if !library.isLocal && player.isLocal && settings.cacheEnabled {
      let newTracks = tracks.filter { !LocalLibrary.sharedInstance.contains($0) }
      let tracksToDownload = newTracks.take(maxNewDownloads)
      log.info("Downloading \(tracksToDownload.count) tracks")
      return tracksToDownload.flatMapOpt { (track) -> ErrorMessage? in
        startDownload(track)
      }
    } else {
      return []
    }
  }
  
  private func startDownload(_ track: Track) -> ErrorMessage? {
    DownloadUpdater.instance.downloadIfNecessary(track: track, authValue: library.authValue)
  }
}
