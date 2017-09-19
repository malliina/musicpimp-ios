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
    
    let log = LoggerFactory.pimp("Local.ExternalCommandDelegate", category: "Local")
    var player: PlayerType { get { return PlayerManager.sharedInstance.active } }
    private var disposable: Disposable? = nil
    
    func initialize(_ commandCenter: MPRemoteCommandCenter) {
        commandCenter.playCommand.addTarget(self, action: #selector(ExternalCommandDelegate.onPlay))
        commandCenter.pauseCommand.addTarget(self, action: #selector(ExternalCommandDelegate.onPause))
        commandCenter.togglePlayPauseCommand.addTarget(self, action: #selector(ExternalCommandDelegate.onTogglePlayPause))
        commandCenter.stopCommand.addTarget(self, action: #selector(ExternalCommandDelegate.onStop))
        commandCenter.nextTrackCommand.addTarget(self, action: #selector(ExternalCommandDelegate.next))
        commandCenter.previousTrackCommand.addTarget(self, action: #selector(ExternalCommandDelegate.prev))
        // these two will visually replace the "prev" and "next" buttons, which I don't want, so I exclude them
//        commandCenter.skipForwardCommand.addTarget(self, action: "skipForward:")
//        commandCenter.skipBackwardCommand.addTarget(self, action: "skipBackward:")
        commandCenter.seekForwardCommand.addTarget(self, action: #selector(ExternalCommandDelegate.seekForward(_:)))
        commandCenter.seekBackwardCommand.addTarget(self, action: #selector(ExternalCommandDelegate.seekBackward(_:)))
        let _ = LocalPlayer.sharedInstance.trackEvent.addHandler(self) { (ecd) -> (Track?) -> () in
            ecd.onLocalTrackChanged
        }
    }
    
    func onLocalTrackChanged(_ track: Track?) -> Void {
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
                    info[MPMediaItemPropertyArtwork] = MPMediaItemArtwork(boundsSize: image.size, requestHandler: { size in image.withSize(scaledToSize: size) })
                }
                center.nowPlayingInfo = info
            }
        } else {
            center.nowPlayingInfo = nil
        }
    }
    
    func onPlay() -> MPRemoteCommandHandlerStatus {
        _ = player.play()
        info("onPlay")
        return .success
    }
    
    func onPause() -> MPRemoteCommandHandlerStatus {
        _ = player.pause()
        info("onPause")
        return .success
    }
    
    func onTogglePlayPause() -> MPRemoteCommandHandlerStatus {
        if player.current().isPlaying {
            _ = player.pause()
        } else {
            _ = player.play()
        }
        info("onTogglePlayPause")
        return .success
    }
    
    func onStop() -> MPRemoteCommandHandlerStatus {
        _ = player.pause()
        info("onStop")
        return .success
    }
    
    func next() -> MPRemoteCommandHandlerStatus {
        _ = player.next()
        info("next")
        return .success
    }
    
    func prev() -> MPRemoteCommandHandlerStatus {
        _ = player.prev()
        info("prev")
        return .success
    }
    
    func skipForward(_ skipEvent: MPSkipIntervalCommandEvent) -> MPRemoteCommandHandlerStatus {
        let interval = skipEvent.interval
        info("skipForward \(interval)")
        return .success
    }
    
    func skipBackward(_ skipEvent: MPSkipIntervalCommandEvent) -> MPRemoteCommandHandlerStatus {
        info("skipBackward")
        return .success
    }
    
    func seekForward(_ seekEvent: MPSeekCommandEvent) -> MPRemoteCommandHandlerStatus {
        let t = seekEvent.type
        info("seekForward \(t)")
        return .success
    }
    
    func seekBackward(_ seekEvent: MPSeekCommandEvent) -> MPRemoteCommandHandlerStatus {
        info("seekBackward")
        return .success
    }
    
    func info(_ s: String) {
        log.info(s)
    }
}
