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

class LocalPlayer: NSObject {
    
    static let sharedInstance = LocalPlayer()
    static let statusKeyPath = "status"
    
    private var localPlaylist = LocalPlaylist()
    
    var playlist: LocalPlaylist { get { return localPlaylist } }
    
    var playerInfo: PlayerInfo? = nil
    var player: AVPlayer? { get { return playerInfo?.player } }
    private var timeObserver: AnyObject? = nil
    private var itemStatusContext = 0
    private var playerStatusContext = 1
    private let notificationCenter = NSNotificationCenter.defaultCenter()
    let stateEvent = Event<PlayerState>()
    let timeEvent = Event<Float>()
    let trackEvent = Event<Track>()
    
    func play() {
        if let playerInfo = playerInfo {
            // TODO see if we can sync this better by only raising the event after confirmation that the player is playing
            playerInfo.player.play()
            stateEvent.raise(.Playing)
        }
    }
    func pause() {
        if let player = player {
            player.pause()
            stateEvent.raise(.Paused)
        }
    }
    func seek(position: Float) {
        // fucking hell
        var scale: Int32 = 1;
        var pos64 = Float64(position)
        var posTime = CMTimeMakeWithSeconds(pos64, scale)
        player?.seekToTime(posTime)
    }
    func duration() -> Float? {
        if let duration = player?.currentItem?.asset?.duration {
            let secs = CMTimeGetSeconds(duration)
            if(secs.isNormal) {
                return Float(secs)
            }
        }
        if let duration = playerInfo?.track.duration {
            let secs = Float(duration)
            if(secs.isNormal) {
                return secs
            }
        }
        return nil
    }
    func position() -> Float? {
        if let currentTime = player?.currentTime() {
            return Float(CMTimeGetSeconds(currentTime))
        }
        return nil
    }
    func next() -> Track? {
        return playFromPlaylist({ $0.next() })
    }
    func prev() -> Track? {
        return playFromPlaylist({ $0.prev() })
    }
    func skip(index: Int) -> Track? {
        return playFromPlaylist({ $0.skip(index) })
    }
    private func playFromPlaylist(f: LocalPlaylist -> Track?) -> Track? {
        if let track = f(playlist) {
            closePlayer()
            initAndPlay(track)
            return track
        }
        return nil
    }
    func resetAndPlay(track: Track) {
        resetAndPlay([track])
    }
    func resetAndPlay(tracks: [Track]) {
        closePlayer()
        playlist.reset(tracks)
        if let first = tracks.first {
            initAndPlay(first)
        }
    }
    private func initAndPlay(track: Track) {
        let urlString = "\(track.url)?u=\(track.username)&p=\(track.password)"
        info("Playing: \(urlString)")
        let url = NSURL(string: urlString)
        let playerItem = AVPlayerItem(URL: url) // , automaticallyLoadedAssetKeys: ["duration"]
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
            let secsFloat = Float(secs)
            self.timeEvent.raise(secsFloat)
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
                    info("Failed")
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