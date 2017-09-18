//
//  PlayerEventDelegate.swift
//  MusicPimp
//
//  Created by Michael Skogberg on 31/05/15.
//  Copyright (c) 2015 Skogberg Labs. All rights reserved.
//

import Foundation

protocol PlayerEventDelegate {
    func parseStatus(_ json: NSDictionary) throws -> PlayerState
    
    func parseTrack(_ json: NSDictionary) throws -> Track
    
    func onTimeUpdated(_ pos: Duration)
    
    func onTrackChanged(_ track: Track?)
    
    func onMuteToggled(_ mute: Bool)
    
    func onVolumeChanged(_ volume: VolumeValue)
    
    func onStateChanged(_ state: PlaybackState)
    
    func onIndexChanged(_ index: Int?)
    
    func onPlaylistModified(_ tracks: [Track])
    
    func onState(_ state: PlayerState)
}

class LoggingDelegate : PlayerEventDelegate {
    let log = LoggerFactory.pimp("Audio.PlayerEventDelegate", category: "Audio")
    
    func parseStatus(_ json: NSDictionary) throws -> PlayerState {
        return PlayerState.empty
    }
    
    func parseTrack(_ json: NSDictionary) throws -> Track {
        return Track.empty
    }
    
    func onTimeUpdated(_ pos: Duration) {
        log("Time: \(pos)")
    }
    
    func onTrackChanged(_ track: Track?) {
        log("Track: \(track?.id ?? "None")")
    }
    
    func onMuteToggled(_ mute: Bool) {
        log("Mute: \(mute)")
    }
    
    func onVolumeChanged(_ volume: VolumeValue) {
        log("Volume: \(volume)")
    }
    
    func onStateChanged(_ state: PlaybackState) {
        log("State: \(state)")
    }
    
    func onIndexChanged(_ index: Int?) {
        log("Index: \(index ?? -1)")
    }
    
    func onPlaylistModified(_ tracks: [Track]) {
        log("Tracks: \(tracks.description)")
    }
    
    func onState(_ state: PlayerState) {
        log("Status")
    }
    
    func log(_ s: String) {
        log.info(s)
    }
}
