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
    
    func initialize(commandCenter: MPRemoteCommandCenter) {
        commandCenter.playCommand.addTarget(self, action: "onPlay")
        commandCenter.pauseCommand.addTarget(self, action: "onPause")
        commandCenter.togglePlayPauseCommand.addTarget(self, action: "onTogglePlayPause")
        commandCenter.stopCommand.addTarget(self, action: "onStop")
        commandCenter.nextTrackCommand.addTarget(self, action: "next")
        commandCenter.previousTrackCommand.addTarget(self, action: "prev")
        // these two will visually replace the "prev" and "next" buttons, which I don't want, so we exclude them
//        commandCenter.skipForwardCommand.addTarget(self, action: "skipForward:")
//        commandCenter.skipBackwardCommand.addTarget(self, action: "skipBackward:")
        commandCenter.seekForwardCommand.addTarget(self, action: "seekForward:")
        commandCenter.seekBackwardCommand.addTarget(self, action: "seekBackward:")
        LocalPlayer.sharedInstance.trackEvent.addHandler(self, handler: { (ecd) -> Track? -> () in
            ecd.onLocalTrackChanged
        })
    }
    func onLocalTrackChanged(track: Track?) {
        let center = MPNowPlayingInfoCenter.defaultCenter()
        if let track = track {
            var info: [String: AnyObject] = [
                MPMediaItemPropertyTitle: track.title,
                MPMediaItemPropertyArtist: track.artist,
                MPMediaItemPropertyAlbumTitle: track.album,
                MPMediaItemPropertyMediaType: MPMediaType.Music.rawValue,
                MPMediaItemPropertyPlaybackDuration: NSTimeInterval(track.duration.seconds)
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
    func skipForward(skipEvent: MPSkipIntervalCommandEvent) {
        let interval = skipEvent.interval
        info("skipForward \(interval)")
    }
    func skipBackward(skipEvent: MPSkipIntervalCommandEvent) {
        info("skipBackward")
    }
    func seekForward(seekEvent: MPSeekCommandEvent) {
        let t = seekEvent.type
        info("seekForward \(t)")
    }
    func seekBackward(seekEvent: MPSeekCommandEvent) {
        info("seekBackward")
    }
    func info(s: String) {
        Log.info(s)
    }
}
