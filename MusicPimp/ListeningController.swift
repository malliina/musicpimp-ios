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

  func onTrackChanged(_ track: Track?) async {
    if let track = track {
      await updateMedia(track)
    } else {
      await updateNoMedia()
    }
  }

  func updateMedia(_ track: Track) async {

  }

  func updateNoMedia() async {

  }

  func onTimeUpdated(_ position: Duration) {

  }

  func onStateChanged(_ state: PlaybackState) {

  }
}
