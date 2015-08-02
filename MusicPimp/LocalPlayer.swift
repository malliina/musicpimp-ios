//
//  LocalPlayer.swift
//  MusicPimp
//
//  Created by Michael Skogberg on 12/04/15.
//  Copyright (c) 2015 Skogberg Labs. All rights reserved.
//

import Foundation
import AudioToolbox
import AVFoundation

class LocalPlayer: NSObject, PlayerType {
    static let sharedInstance = LocalPlayer()
    static let statusKeyPath = "status"
    
    var isLocal: Bool { get { return true } }
    
    private var localPlaylist = LocalPlaylist()
    
    var playlist: PlaylistType { get { return localPlaylist } }
    var playerInfo: PlayerInfo? = nil
    var player: AVPlayer? { get { return playerInfo?.player } }
    private var timeObserver: AnyObject? = nil
    private var itemStatusContext = 0
    private var playerStatusContext = 1
    private let notificationCenter = NSNotificationCenter.defaultCenter()
    let stateEvent = Event<PlaybackState>()
    let timeEvent = Event<Duration>()
    let trackEvent = Event<Track?>()
    let volumeEvent = Event<Int>()
    let muteEvent = Event<Bool>()
    
    func open() {
        
    }
    func close() {
        
    }
    func current() -> PlayerState {
        let list = localPlaylist.current()
        let pos = position() ?? Duration.Zero
        return PlayerState(
            track: playerInfo?.track,
            state: playbackState(),
            position: pos,
            volume: 40,
            mute: false,
            playlist: list.tracks,
            playlistIndex: list.index)
    }
    func playbackState() -> PlaybackState {
        if let p = playerInfo?.player {
            if (p.error != nil) {
                return PlaybackState.Unknown
            }
            return p.rate > 0 ? .Playing : .Paused
        } else {
            return .NoMedia
        }
    }
    func play() {
        if let playerInfo = playerInfo {
            // TODO see if we can sync this better by only raising the event after confirmation that the player is playing
            playerInfo.player.play()
            stateEvent.raise(.Playing)
            Log.info("Playback should now start")
        } else {
            Log.error("There is no player; will not play.")
        }
    }
    func pause() {
        if let player = player {
            player.pause()
            stateEvent.raise(.Paused)
        }
    }
    func seek(position: Duration) {
        // fucking hell
        var scale: Int32 = 1
        var pos64 = Float64(position.seconds)
        var posTime = CMTimeMakeWithSeconds(pos64, scale)
        player?.seekToTime(posTime)
    }
    
    func duration() -> Duration? {
        if let metas = player?.currentItem?.asset?.metadata as? [AVMetadataItem] {
            for meta: AVMetadataItem in metas {
                let key = meta.key
                let value = meta.stringValue
                let keyStr = key.description
            }
        } else {
            info ("No meta")
        }
        if let duration = player?.currentItem?.asset?.duration {
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
    func next() {
        playFromPlaylist({ $0.next() })
    }
    func prev() {
        playFromPlaylist({ $0.prev() })
    }
    func skip(index: Int) {
        playFromPlaylist({ $0.skip(index) })
    }
    private func playFromPlaylist(f: LocalPlaylist -> Track?) -> Track? {
        if let track = f(localPlaylist) {
            closePlayer()
            initAndPlay(track)
            return track
        } else {
            Log.info("Unable to find track from playlist")
            return nil
        }
        
    }
    func resetAndPlay(track: Track) {
        resetAndPlay([track])
    }
    func resetAndPlay(tracks: [Track]) {
        closePlayer()
        localPlaylist.reset(tracks)
        if let first = tracks.first {
            initAndPlay(first)
        }
    }
    private func initAndPlay(track: Track) {
        info("Playing \(track.title)")
        let preferredUrl = LocalLibrary.sharedInstance.url(track) ?? track.url
        let playerItem = AVPlayerItem(URL: preferredUrl)
        playerItem.addObserver(self, forKeyPath: LocalPlayer.statusKeyPath, options: NSKeyValueObservingOptions.Initial, context: &itemStatusContext)
        let p = AVPlayer(playerItem: playerItem)
        notificationCenter.addObserver(self,
            selector: "playedToEnd:",
            name: AVPlayerItemDidPlayToEndTimeNotification,
            object: p.currentItem)
        notificationCenter.addObserver(self,
            selector: "failedToPlayToEnd:",
            name: AVPlayerItemFailedToPlayToEndTimeNotification,
            object: p.currentItem)
        p.addObserver(self, forKeyPath: LocalPlayer.statusKeyPath, options: NSKeyValueObservingOptions.Initial, context: &playerStatusContext)
        playerInfo = PlayerInfo(player: p, track: track)
        trackEvent.raise(track)
        timeObserver = player?.addPeriodicTimeObserverForInterval(CMTimeMakeWithSeconds(1, 1), queue: dispatch_get_main_queue()) { (time) -> Void in
            let secs = CMTimeGetSeconds(time)
            if let duration = secs.seconds {
                self.timeEvent.raise(duration)
            } else {
                Log.error("Unable to convert time to Duration: \(secs)")
            }
        }
        play()
    }
    @objc func playedToEnd(notification: NSNotification) {
        info("Playback ended.")
        next()
    }
    @objc func failedToPlayToEnd(notification: NSNotification) {
        info("Failed to play to end.")
        next()
    }
    override func observeValueForKeyPath(keyPath: String, ofObject object: AnyObject, change: [NSObject: AnyObject], context: UnsafeMutablePointer<Void>) {
        if context == &itemStatusContext {
            if let item = object as? AVPlayerItem {
                switch(item.status) {
                case AVPlayerItemStatus.Failed:
                    info("AVPlayerItemStatus.Failed")
                    closePlayer()
                default:
                    let temp = 0
                }
            } else {
                Log.info("Non-item object")
            }
        } else if context == &playerStatusContext {
            if let p = object as? AVPlayer {
                switch(p.status) {
                case AVPlayerStatus.Failed:
                    info("Player failed")
                default:
                    let temp = 0
//                    info("Player other")
                }
            } else {
                info("Non-player object")
            }
        } else {
            super.observeValueForKeyPath(keyPath, ofObject: object, change: change, context: context)
        }
    }
    
    func closePlayer() {
        if let player = player {
//            info("Closing player")
            if let item = player.currentItem {
                item.removeObserver(self, forKeyPath: LocalPlayer.statusKeyPath, context: &itemStatusContext)
            }
            player.removeObserver(self, forKeyPath: LocalPlayer.statusKeyPath, context: &playerStatusContext)
            if let timeObserver: AnyObject = timeObserver {
                player.removeTimeObserver(timeObserver)
            }
            notificationCenter.removeObserver(self, name: AVPlayerItemDidPlayToEndTimeNotification, object: player.currentItem)
            notificationCenter.removeObserver(self, name: AVPlayerItemFailedToPlayToEndTimeNotification, object: player.currentItem)
            timeObserver = nil
        }
        playerInfo = nil
    }
    
    func info(s: String) {
        Log.info(s)
    }
}