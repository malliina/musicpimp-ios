import Foundation
import RxSwift

class BasePlayer: NSObject {
  @Published var state: PlaybackState?
  var stateEvent: Published<PlaybackState?>.Publisher { $state }
  @Published var time: Duration?
  var timeEvent: Published<Duration?>.Publisher { $time }
  @Published var volume: VolumeValue?
  var volumeEvent: Published<VolumeValue?>.Publisher { $volume }
  @Published var track: Track?
  var trackEvent: Published<Track?>.Publisher { $track }
}

protocol PlayerType {
  var id: String { get }
  var isLocal: Bool { get }
  var stateEvent: Published<PlaybackState?>.Publisher { get }
  var timeEvent: Published<Duration?>.Publisher { get }
  var volumeEvent: Published<VolumeValue?>.Publisher { get }
  var trackEvent: Published<Track?>.Publisher { get }
  var playlist: PlaylistType { get }

  func open() async -> URL

  func close()

  func current() -> PlayerState

  /// Resets the playlist to the given track only, and starts playback.
  ///
  /// - parameter track: track to play
  ///
  /// - returns: an error message, if any
  func resetAndPlay(tracks: [Track]) async -> ErrorMessage?

  func play() async -> ErrorMessage?

  func pause() async -> ErrorMessage?

  func seek(_ position: Duration) async -> ErrorMessage?

  func next() async -> ErrorMessage?

  func prev() async -> ErrorMessage?

  func skip(_ index: Int) async -> ErrorMessage?

  func volume(_ newVolume: VolumeValue) async -> ErrorMessage?
}

extension PlayerType {
  /// Restores this player with the given state. Used to switch from one listening device to another (e.g. remote to local),
  /// maintaining the state of the previous player.
  ///
  /// - parameter state: player state to restore, including the track and any playlist
  func handover(state: PlayerState) async -> [ErrorMessage] {
    let pauseResult = await pause()
    let resetResult = await playlist.reset(state.playlistIndex, tracks: state.playlist)
    let skipResult = await restoreIndex(idx: state.playlistIndex)
    let seekResult = await seek(state.position)
    let playResult = state.isPlaying ? await play() : await pause()
    return [pauseResult, resetResult, skipResult, seekResult, playResult].flatMapOpt { $0 }
  }

  private func restoreIndex(idx: Int?) async -> ErrorMessage? {
    return if let idx = idx {
      await skip(idx)
    } else {
      nil
    }
  }
}
