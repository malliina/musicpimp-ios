
import Foundation
import RxSwift

protocol PlayerType {
    var isLocal: Bool { get }
    var stateEvent: Observable<PlaybackState> { get }
    var timeEvent: Observable<Duration> { get }
    var volumeEvent: Observable<VolumeValue> { get }
    var trackEvent: Observable<Track?> { get }
    var playlist: PlaylistType { get }
    
    func open() -> Observable<Void>
    
    func close()
    
    func current() -> PlayerState
    
    /// Resets the playlist to the given track only, and starts playback.
    ///
    /// - parameter track: track to play
    ///
    /// - returns: an error message, if any
    func resetAndPlay(tracks: [Track]) -> ErrorMessage?
    
    func play() -> ErrorMessage?
    
    func pause() -> ErrorMessage?
    
    func seek(_ position: Duration) -> ErrorMessage?
    
    func next() -> ErrorMessage?
    
    func prev() -> ErrorMessage?
    
    func skip(_ index: Int) -> ErrorMessage?
    
    func volume(_ newVolume: VolumeValue) -> ErrorMessage?
}

extension PlayerType {
    /// Restores this player with the given state. Used to switch from one listening device to another (e.g. remote to local),
    /// maintaining the state of the previous player.
    ///
    /// - parameter state: player state to restore, including the track and any playlist
    func handover(state: PlayerState) -> [ErrorMessage] {
        let pauseResult = pause()
        let resetResult = playlist.reset(state.playlistIndex, tracks: state.playlist)
        let skipResult = restoreIndex(idx: state.playlistIndex)
        let seekResult = seek(state.position)
        let playResult = state.isPlaying ? play() : pause()
        return [pauseResult, resetResult, skipResult, seekResult, playResult].flatMapOpt { $0 }
    }
    
    private func restoreIndex(idx: Int?) -> ErrorMessage? {
        if let idx = idx {
            return skip(idx)
        } else {
            return nil
        }
    }

}
