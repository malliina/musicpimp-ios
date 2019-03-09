//
//  ExternalCommandDelegate.swift
//  MusicPimp
//
//  Created by Michael Skogberg on 19/07/15.
//  Copyright (c) 2015 Skogberg Labs. All rights reserved.
//

import Foundation
import MediaPlayer
import RxSwift

class ExternalCommandDelegate: NSObject {
    static let sharedInstance = ExternalCommandDelegate()
    
    let log = LoggerFactory.shared.pimp(ExternalCommandDelegate.self)
    var player: PlayerType { get { return PlayerManager.sharedInstance.active } }
    private var disposable: Disposable? = nil
    
    let bag = DisposeBag()
    
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
        LocalPlayer.sharedInstance.trackEvent.subscribe(onNext: { (track) in
            self.onLocalTrackChanged(track)
        }).disposed(by: bag)
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
            
            let _ = CoverService.sharedInstance.cover(track.artist, album: track.album).subscribe(onSuccess: { (result) in
                if let image = result.imageOrDefault {
                    info[MPMediaItemPropertyArtwork] = MPMediaItemArtwork(boundsSize: image.size, requestHandler: { size in image.withSize(scaledToSize: size) })
                }
                center.nowPlayingInfo = info
            }) { (err) in
                self.log.error("Failed to fetch cover for '\(track.artist) - \(track.album). \(err)")
            }
        } else {
            center.nowPlayingInfo = nil
        }
    }
    
    @objc func onPlay() -> MPRemoteCommandHandlerStatus {
        _ = player.play()
        info("onPlay")
        return .success
    }
    
    @objc func onPause() -> MPRemoteCommandHandlerStatus {
        _ = player.pause()
        info("onPause")
        return .success
    }
    
    @objc func onTogglePlayPause() -> MPRemoteCommandHandlerStatus {
        if player.current().isPlaying {
            _ = player.pause()
        } else {
            _ = player.play()
        }
        info("onTogglePlayPause")
        return .success
    }
    
    @objc func onStop() -> MPRemoteCommandHandlerStatus {
        _ = player.pause()
        info("onStop")
        return .success
    }
    
    @objc func next() -> MPRemoteCommandHandlerStatus {
        _ = player.next()
        info("next")
        return .success
    }
    
    @objc func prev() -> MPRemoteCommandHandlerStatus {
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
    
    @objc func seekForward(_ seekEvent: MPSeekCommandEvent) -> MPRemoteCommandHandlerStatus {
        let t = seekEvent.type
        info("seekForward \(t)")
        return .success
    }
    
    @objc func seekBackward(_ seekEvent: MPSeekCommandEvent) -> MPRemoteCommandHandlerStatus {
        info("seekBackward")
        return .success
    }
    
    func info(_ s: String) {
        log.info(s)
    }
}
