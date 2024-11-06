import Foundation

class PlayerStateClass {
  static let empty = PlayerStateClass(
    track: nil, state: .NoMedia, position: 0, volume: 40, mute: false, playlist: [],
    playlistIndex: nil)

  let track: Track?
  let state: PlaybackState
  let position: Int
  let volume: Int
  let mute: Bool
  let playlist: [Track]
  let playlistIndex: Int?

  var isPlaying: Bool { state == .Playing }

  init(
    track: Track?, state: PlaybackState, position: Int, volume: Int, mute: Bool, playlist: [Track],
    playlistIndex: Int?
  ) {
    self.track = track
    self.state = state
    self.position = position
    self.volume = volume
    self.mute = mute
    self.playlist = playlist
    self.playlistIndex = playlistIndex
  }
}

struct PlayerStateJson: Codable {
  static let empty = PlayerStateJson(
    track: nil, state: .closed, position: Duration.Zero, volume: VolumeValue.Default, mute: false,
    playlist: [], index: nil)

  let track: Track?
  let state: PlayStateJson
  let position: Duration
  let volume: VolumeValue
  let mute: Bool
  let playlist: [Track]
  let index: Int?

  var playbackState: PlaybackState { return state.playbackState }
  var isPlaying: Bool { return state.playbackState == .Playing }

  func mutable() -> PlayerState {
    return PlayerState(
      track: track, state: state.playbackState, position: position, volume: volume, mute: mute,
      playlist: playlist, playlistIndex: index)
  }
}

struct PlayerState {
  static let empty = PlayerState(
    track: nil, state: .NoMedia, position: Duration.Zero, volume: VolumeValue.Default, mute: false,
    playlist: [], playlistIndex: nil)

  var track: Track?
  var state: PlaybackState
  var position: Duration
  var volume: VolumeValue
  var mute: Bool
  var playlist: [Track]
  var playlistIndex: Int?
  var isPlaying: Bool { state == .Playing }
}
