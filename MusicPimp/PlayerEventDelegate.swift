import Foundation

protocol PlayerEventDelegate {
  func onTimeUpdated(_ pos: Duration)

  func onTrackChanged(_ track: Track?)

  func onMuteToggled(_ mute: Bool)

  func onVolumeChanged(_ volume: VolumeValue)

  func onStateChanged(_ state: PlaybackState)

  func onIndexChanged(_ index: Int?)

  func onPlaylistModified(_ tracks: [Track])

  func onState(_ state: PlayerStateJson)
}

class LoggingDelegate: PlayerEventDelegate {
  let log = LoggerFactory.shared.pimp(LoggingDelegate.self)

  func onTimeUpdated(_ pos: Duration) {
    log("Time: \(pos)")
  }

  func onTrackChanged(_ track: Track?) {
    log("Track: \(track?.id.id ?? "None")")
  }

  func onMuteToggled(_ mute: Bool) {
    log("Mute: \(mute)")
  }

  func onVolumeChanged(_ volume: VolumeValue) {
    log("Volume: \(volume)")
  }

  func onStateChanged(_ state: PlaybackState) {
    log("State: \(state)")
  }

  func onIndexChanged(_ index: Int?) {
    log("Index: \(index ?? -1)")
  }

  func onPlaylistModified(_ tracks: [Track]) {
    log("Tracks: \(tracks.description)")
  }

  func onState(_ state: PlayerStateJson) {
    log("Status")
  }

  func log(_ s: String) {
    log.info(s)
  }
}
