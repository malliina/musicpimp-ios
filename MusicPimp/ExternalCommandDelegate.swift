//
//  ExternalCommandDelegate.swift
//  MusicPimp
//
//  Created by Michael Skogberg on 19/07/15.
//  Copyright (c) 2015 Skogberg Labs. All rights reserved.
//

import Foundation
import MediaPlayer

class ExternalCommandDelegate: NSObject {
    static let sharedInstance = ExternalCommandDelegate()
    
    var player: PlayerType { get { return PlayerManager.sharedInstance.active } }
    
    func initialize(_ commandCenter: MPRemoteCommandCenter) {
        commandCenter.playCommand.addTarget(self, action: #selector(ExternalCommandDelegate.onPlay))
        commandCenter.pauseCommand.addTarget(self, action: #selector(ExternalCommandDelegate.onPause))
        commandCenter.togglePlayPauseCommand.addTarget(self, action: #selector(ExternalCommandDelegate.onTogglePlayPause))
        commandCenter.stopCommand.addTarget(self, action: #selector(ExternalCommandDelegate.onStop))
        commandCenter.nextTrackCommand.addTarget(self, action: #selector(ExternalCommandDelegate.next))
        commandCenter.previousTrackCommand.addTarget(self, action: #selector(ExternalCommandDelegate.prev))
        // these two will visually replace the "prev" and "next" buttons, which I don't want, so we exclude them
//        commandCenter.skipForwardCommand.addTarget(self, action: "skipForward:")
//        commandCenter.skipBackwardCommand.addTarget(self, action: "skipBackward:")
        commandCenter.seekForwardCommand.addTarget(self, action: #selector(ExternalCommandDelegate.seekForward(_:)))
        commandCenter.seekBackwardCommand.addTarget(self, action: #selector(ExternalCommandDelegate.seekBackward(_:)))
        LocalPlayer.sharedInstance.trackEvent.addHandler(self, handler: { (ecd) -> (Track?) -> () in
            ecd.onLocalTrackChanged
        })
    }
    
    func onLocalTrackChanged(_ track: Track?) {
        let center = MPNowPlayingInfoCenter.default()
        if let track = track {
            var info: [String: AnyObject] = [
                MPMediaItemPropertyTitle: track.title as AnyObject,
                MPMediaItemPropertyArtist: track.artist as AnyObject,
                MPMediaItemPropertyAlbumTitle: track.album as AnyObject,
                MPMediaItemPropertyMediaType: MPMediaType.music.rawValue as AnyObject,
                MPMediaItemPropertyPlaybackDuration: TimeInterval(track.duration.seconds) as AnyObject
            ]
            
            CoverService.sharedInstance.cover(track.artist, album: track.album) {
                (result) -> Void in
                if let image = result.imageOrDefault {
                    info[MPMediaItemPropertyArtwork] = MPMediaItemArtwork(image: image)
                }
                center.nowPlayingInfo = info
            }
        } else {
            center.nowPlayingInfo = nil
        }
    }
    
    func onPlay() {
        player.play()
        info("onPlay")
    }
    
    func onPause() {
        player.pause()
        info("onPause")
    }
    
    func onTogglePlayPause() {
        if player.current().isPlaying {
            player.pause()
        } else {
            player.play()
        }
        info("onTogglePlayPause")
    }
    
    func onStop() {
        player.pause()
        info("onStop")
    }
    
    func next() {
        player.next()
        info("next")
    }
    
    func prev() {
        player.prev()
        info("prev")
    }
    
    func skipForward(_ skipEvent: MPSkipIntervalCommandEvent) {
        let interval = skipEvent.interval
        info("skipForward \(interval)")
    }
    
    func skipBackward(_ skipEvent: MPSkipIntervalCommandEvent) {
        info("skipBackward")
    }
    
    func seekForward(_ seekEvent: MPSeekCommandEvent) {
        let t = seekEvent.type
        info("seekForward \(t)")
    }
    
    func seekBackward(_ seekEvent: MPSeekCommandEvent) {
        info("seekBackward")
    }
    
    func info(_ s: String) {
        Log.info(s)
    }
}
