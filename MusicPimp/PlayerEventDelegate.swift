//
//  PlayerEventDelegate.swift
//  MusicPimp
//
//  Created by Michael Skogberg on 31/05/15.
//  Copyright (c) 2015 Skogberg Labs. All rights reserved.
//

import Foundation
protocol PlayerEventDelegate {
    func parseStatus(json: NSDictionary) -> PlayerState?
    func parseTrack(json: NSDictionary) -> Track?
    func onTimeUpdated(pos: Duration)
    func onTrackChanged(track: Track?)
    func onMuteToggled(mute: Bool)
    func onVolumeChanged(volume: Int)
    func onStateChanged(state: PlaybackState)
    func onIndexChanged(index: Int?)
    func onPlaylistModified(tracks: [Track])
    func onState(state: PlayerState)
}

class LoggingDelegate : PlayerEventDelegate {
    func parseStatus(json: NSDictionary) -> PlayerState? {
        return nil
    }
    func parseTrack(json: NSDictionary) -> Track? {
        return nil
    }
    func onTimeUpdated(pos: Duration) {
        log("Time: \(pos)")
    }
    func onTrackChanged(track: Track?) {
        log("Track: \(track?.id)")
    }
    func onMuteToggled(mute: Bool) {
        log("Mute: \(mute)")
    }
    func onVolumeChanged(volume: Int) {
        log("Volume: \(volume)")
    }
    func onStateChanged(state: PlaybackState) {
        log("State: \(state)")
    }
    func onIndexChanged(index: Int?) {
        log("Index: \(index)")
    }
    func onPlaylistModified(tracks: [Track]) {
        log("Tracks: \(tracks.description)")
    }
    func onState(state: PlayerState) {
        log("Status")
    }
    func log(s: String) {
        Log.info(s)
    }
}
