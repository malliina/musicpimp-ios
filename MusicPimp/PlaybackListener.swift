import Foundation

class BaseListener {
  var tasks: [Task<(), Never>] = []

  func unsubscribe() {
    tasks.forEach { task in
      task.cancel()
    }
    tasks = []
  }
}

protocol LibraryDelegate {
  func onLibraryUpdated(to newLibrary: LibraryType) async
}

class LibraryListener: BaseListener {
  let log = LoggerFactory.shared.system(LibraryListener.self)
  var delegate: LibraryDelegate? = nil

  static let library = LibraryListener()
  static let playlists = LibraryListener()

  private var subscribed = false

  func subscribe() {
    if !subscribed {
      subscribed = true
      //    log.info("Subscribing to library listener...")
      let task = Task {
        await subscribeEternally()
      }
      tasks = [task]
    }
  }

  private func subscribeEternally() async {
    for await library in LibraryManager.sharedInstance.$libraryUpdated.dropFirst().removeDuplicates(
      by: { l1, l2 in
        return l1.id == l2.id
      }).values
    {
      //      log.info("Updated to library \(library.id).")
      await delegate?.onLibraryUpdated(to: library)
    }
  }
}

protocol LibraryEndpointDelegate {
  func onLibraryUpdated(to newLibrary: Endpoint)
}

protocol PlayerEndpointDelegate {
  func onPlayerUpdated(to newPlayer: Endpoint)
}

class EndpointsListener: BaseListener {
  let log = LoggerFactory.shared.system(EndpointsListener.self)
  var libraries: LibraryEndpointDelegate? = nil
  var players: PlayerEndpointDelegate? = nil

  func subscribe() {
    let t1 = Task {
      for await library in LibraryManager.sharedInstance.$changed.nonNilValues() {
        //          log.info("Changing to library \(library)")
        libraryUpdated(library)
      }
    }
    let t2 = Task {
      for await player in PlayerManager.sharedInstance.$changed.nonNilValues() {
        playerChanged(player)
      }
    }
    tasks.append(contentsOf: [t1, t2])
  }

  private func libraryUpdated(_ newLibrary: Endpoint) {
    libraries?.onLibraryUpdated(to: newLibrary)
  }

  private func playerChanged(_ newPlayer: Endpoint) {
    players?.onPlayerUpdated(to: newPlayer)
  }
}

protocol PlayersDelegate {
  func onPlayerChanged(to newPlayer: PlayerType)
}
protocol TrackEventDelegate {
  func onTrackChanged(_ track: Track?) async
}
protocol PlaybackEventDelegate: TrackEventDelegate {
  func onTimeUpdated(_ position: Duration)
  func onStateChanged(_ state: PlaybackState)
}
protocol PlaylistEventDelegate {
  func onIndexChanged(to index: Int?)
  func onNewPlaylist(_ playlist: Playlist)
}

class PlaybackListener: BaseListener {
  let log = LoggerFactory.shared.system(PlaybackListener.self)

  var playerManager: PlayerManager { PlayerManager.sharedInstance }
  var player: PlayerType { playerManager.playerChanged }
  var tracks: TrackEventDelegate? = nil
  var playbacks: PlaybackEventDelegate? = nil
  var playlists: PlaylistEventDelegate? = nil

  private var playbackTasks: [Task<(), Never>] = []
  
  func subscribe() {
    unsubscribe()
    //    log.info("Subscribing to playback events...")
    let task = Task {
      for await player in playerManager.$playerChanged.removeDuplicates(by: { p1, p2 in
        p1.id == p2.id
      }).values {
        playbackTasks.forEach { task in
          task.cancel()
        }
        playbackTasks = subscribe(to: player)
      }
    }
    tasks.append(task)
  }
  
  override func unsubscribe() {
    super.unsubscribe()
    playbackTasks.forEach { task in
      task.cancel()
    }
    playbackTasks = []
  }

  private func subscribe(to newPlayer: PlayerType) -> [Task<(), Never>] {
    let t1 = Task {
      for await playlist in player.playlist.playlistPublisher.nonNilValues() {
        playlists?.onNewPlaylist(playlist)
      }
    }
    let t2 = Task {
      for await index in player.playlist.indexPublisher.values {
        playlists?.onIndexChanged(to: index)
      }
    }
    let t3 = Task {
      for await track in newPlayer.trackEvent.values {
        await tracks?.onTrackChanged(track)
        await playbacks?.onTrackChanged(track)
      }
    }
    let t4 = Task {
      for await time in newPlayer.timeEvent.nonNilValues() {
        playbacks?.onTimeUpdated(time)
      }
    }
    let t5 = Task {
      for await state in newPlayer.stateEvent.nonNilValues() {
        playbacks?.onStateChanged(state)
      }
    }
    return [t1, t2, t3, t4, t5]
  }
}
