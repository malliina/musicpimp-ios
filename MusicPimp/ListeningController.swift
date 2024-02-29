import Foundation

class ListeningController: PimpViewController, PlaybackEventDelegate {
  var playerManager: PlayerManager { PlayerManager.sharedInstance }
  var player: PlayerType { playerManager.playerChanged }

  var libraryManager: LibraryManager { LibraryManager.sharedInstance }
  var library: LibraryType { libraryManager.libraryUpdated }

  let listener = PlaybackListener()

  override func viewDidLoad() {
    super.viewDidLoad()
    listener.playbacks = self
  }

  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    listener.subscribe()
  }

  override func viewDidDisappear(_ animated: Bool) {
    super.viewDidDisappear(animated)
    listener.unsubscribe()
  }

  func onTrackChanged(_ track: Track?) {
    if let track = track {
      updateMedia(track)
    } else {
      updateNoMedia()
    }
  }

  func updateMedia(_ track: Track) {

  }

  func updateNoMedia() {

  }

  func onTimeUpdated(_ position: Duration) {

  }

  func onStateChanged(_ state: PlaybackState) {

  }
}
