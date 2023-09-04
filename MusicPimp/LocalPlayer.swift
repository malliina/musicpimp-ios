
import Foundation
import AudioToolbox
import AVFoundation
import RxSwift

class LocalPlayer: NSObject, PlayerType {
    let log = LoggerFactory.shared.pimp(LocalPlayer.self)
    static let sharedInstance = LocalPlayer()
    static let statusKeyPath = "status"
    
    let limiter = Limiter.sharedInstance
    var isLocal: Bool { get { true } }
    
    fileprivate let localPlaylist = LocalPlaylist.sharedInstance
    
    var playlist: PlaylistType { get { localPlaylist } }
    var playerInfo: PlayerInfo? = nil
    var player: AVPlayer? { get { playerInfo?.player } }
    
    fileprivate var timeObserver: AnyObject? = nil
    fileprivate static var itemStatusContext = 0
    fileprivate static var playerStatusContext = 1
    fileprivate let notificationCenter = NotificationCenter.default
    
    let stateSubject = PublishSubject<PlaybackState>()
    var stateEvent: Observable<PlaybackState> { return stateSubject }
    let timeSubject = PublishSubject<Duration>()
    var timeEvent: Observable<Duration> { return timeSubject }
    let trackSubject = PublishSubject<Track?>()
    var trackEvent: Observable<Track?> { return trackSubject }
    let volumeSubject = PublishSubject<VolumeValue>()
    var volumeEvent: Observable<VolumeValue> { return volumeSubject }
    let muteSubject = PublishSubject<Bool>()
    var muteEvent: Observable<Bool> { return muteSubject }
    let noPlayerError = ErrorMessage("No player")
    let noTrackError = ErrorMessage("No track")
    
    func open() -> Observable<Void> {
        return Observable.empty()
    }
    
    func close() {
        
    }
    
    func current() -> PlayerState {
        let list = localPlaylist.current()
        let pos = position() ?? Duration.Zero
        let volFloat = player?.volume ?? 0.4
        let vol = VolumeValue(volumeFloat: volFloat)
        return PlayerState(
            track: playerInfo?.track,
            state: playbackState(),
            position: pos,
            volume: vol,
            mute: false,
            playlist: list.tracks,
            playlistIndex: list.index)
    }
    
    func playbackState() -> PlaybackState {
        if let p = playerInfo?.player {
            if (p.error != nil) {
                return .Unknown
            }
            return p.rate > 0 ? .Playing : .Paused
        } else {
            return .NoMedia
        }
    }
    
    func play() -> ErrorMessage? {
        if let playerInfo = playerInfo {
            // TODO see if we can sync this better by only raising the event after confirmation that the player is playing
            playerInfo.player.play()
            stateSubject.onNext(.Playing)
            return nil
        } else {
            return noPlayerError
        }
    }
    
    func pause()  -> ErrorMessage? {
        if let player = player {
            player.pause()
            stateSubject.onNext(.Paused)
            return nil
        } else {
            return noPlayerError
        }
    }
    
    func seek(_ position: Duration) -> ErrorMessage? {
        // fucking hell
        let scale: Int32 = 1
        let pos64 = Float64(position.seconds)
        let posTime = CMTimeMakeWithSeconds(pos64, preferredTimescale: scale)
        if let player = player {
            player.seek(to: posTime)
            return nil
        } else {
            return noPlayerError
        }
    }
    
    func volume(_ newVolume: VolumeValue) -> ErrorMessage? {
        if let player = player {
            player.volume = newVolume.toFloat()
            return nil
        } else {
            return noPlayerError
        }
    }
    
    func duration() -> Duration? {
        if let duration = player?.currentItem?.asset.duration {
            let secs = CMTimeGetSeconds(duration)
            if(secs.isNormal) {
                return secs.seconds
            }
        }
        return playerInfo?.track.duration
    }
    
    func position() -> Duration? {
        if let currentTime = player?.currentTime() {
            return Float(CMTimeGetSeconds(currentTime)).seconds
        }
        return nil
    }
    
    func next() -> ErrorMessage? {
        withPlaylist { $0.next() }
    }
    
    func prev() -> ErrorMessage? {
        withPlaylist { $0.prev() }
    }
    
    func skip(_ index: Int) -> ErrorMessage? {
        withPlaylist { $0.skip(index) }
    }
    
    func withPlaylist(_ f: (LocalPlaylist) -> Track?) -> ErrorMessage? {
        if let _ = playFromPlaylist(f) {
            return nil
        } else {
            stateSubject.onNext(.NoMedia)
            return noTrackError
        }
    }
    
    fileprivate func playFromPlaylist(_ f: (LocalPlaylist) -> Track?) -> Track? {
        if let track = f(localPlaylist) {
            closePlayer()
            let _ = initAndPlay(track)
            return track
        } else {
            log.info("Unable to find track from playlist")
            return nil
        }
    }
    
    func resetAndPlay(tracks: [Track]) -> ErrorMessage? {
        closePlayer()
        let _ = localPlaylist.reset(tracks)
        guard let first = tracks.first else { return nil }
        return initAndPlay(first)
    }
    
    /// Adds credentials to the query parameters of remote URLs because I cannot set headers in AVPlayer
    private func buildUrl(track: Track) -> URL {
        let noQuery = LocalLibrary.sharedInstance.url(track) ?? track.url
        let authQuery = LibraryManager.sharedInstance.active.authQuery
        if !noQuery.isFile && !authQuery.isEmpty {
            return URL(string: "\(noQuery.absoluteString)?\(authQuery)") ?? noQuery
        }
        return noQuery
    }
    
    fileprivate func initAndPlay(_ track: Track) -> ErrorMessage? {
        limiter.increment()
        let playerItem = AVPlayerItem(url: buildUrl(track: track))
        playerItem.addObserver(self, forKeyPath: LocalPlayer.statusKeyPath, options: .initial, context: &LocalPlayer.itemStatusContext)
        let p = AVPlayer(playerItem: playerItem)
        notificationCenter.addObserver(self,
            selector: #selector(LocalPlayer.playedToEnd(_:)),
            name: NSNotification.Name.AVPlayerItemDidPlayToEndTime,
            object: p.currentItem)
        notificationCenter.addObserver(self,
            selector: #selector(LocalPlayer.failedToPlayToEnd(_:)),
            name: NSNotification.Name.AVPlayerItemFailedToPlayToEndTime,
            object: p.currentItem)
        p.addObserver(self, forKeyPath: LocalPlayer.statusKeyPath, options: .initial, context: &LocalPlayer.playerStatusContext)
        playerInfo = PlayerInfo(player: p, track: track)
        trackSubject.onNext(track)
        timeObserver = player?.addPeriodicTimeObserver(forInterval: CMTimeMakeWithSeconds(1, preferredTimescale: 1), queue: .main) { (time) -> Void in
            let secs = CMTimeGetSeconds(time)
            if let duration = secs.seconds {
                self.timeSubject.onNext(duration)
            } else {
                self.log.error("Unable to convert time to Duration: \(secs)")
            }
        } as AnyObject?
        return play()
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey: Any]?, context: UnsafeMutableRawPointer?) {
        if context == &LocalPlayer.itemStatusContext {
            if let item = object as? AVPlayerItem {
                switch(item.status) {
                case AVPlayerItem.Status.failed:
                    self.log.info("AVPlayerItemStatus.Failed")
                    closePlayer()
                default:
                    break
                }
            } else {
                log.info("Non-item object")
            }
        } else if context == &LocalPlayer.playerStatusContext {
            if let p = object as? AVPlayer {
                switch(p.status) {
                case AVPlayer.Status.failed:
                    self.log.error("Player failed")
                default:
                    break
                }
            } else {
                self.log.info("Non-player object")
            }
        } else {
            super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
        }
    }
    
    @objc func playedToEnd(_ notification: Notification) {
        log.info("Playback ended.")
        _ = next()
    }
    
    @objc func failedToPlayToEnd(_ notification: Notification) {
        log.info("Failed to play to end.")
        _ = next()
    }
    
    func closePlayer() {
        if let player = player {
            if let item = player.currentItem {
                item.removeObserver(self, forKeyPath: LocalPlayer.statusKeyPath, context: &LocalPlayer.itemStatusContext)
            }
            player.removeObserver(self, forKeyPath: LocalPlayer.statusKeyPath, context: &LocalPlayer.playerStatusContext)
            if let timeObserver: AnyObject = timeObserver as AnyObject? {
                player.removeTimeObserver(timeObserver)
            }
            notificationCenter.removeObserver(self, name: NSNotification.Name.AVPlayerItemDidPlayToEndTime, object: player.currentItem)
            notificationCenter.removeObserver(self, name: NSNotification.Name.AVPlayerItemFailedToPlayToEndTime, object: player.currentItem)
            timeObserver = nil
        }
        playerInfo = nil
    }
}
