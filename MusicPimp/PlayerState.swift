//
//  PimpStatus.swift
//  MusicPimp
//
//  Created by Michael Skogberg on 23/05/15.
//  Copyright (c) 2015 Skogberg Labs. All rights reserved.
//

import Foundation

class PlayerStateClass {
    static let empty = PlayerStateClass(track: nil, state: .NoMedia, position: 0, volume: 40, mute: false, playlist: [], playlistIndex: nil)
    
    let track: Track?
    let state: PlaybackState
    let position: Int
    let volume: Int
    let mute: Bool
    let playlist: [Track]
    let playlistIndex: Int?
    
    var isPlaying: Bool { get { return state == .Playing } }
    
    init(track: Track?, state: PlaybackState, position: Int, volume: Int, mute: Bool, playlist: [Track], playlistIndex: Int?) {
        self.track = track
        self.state = state
        self.position = position
        self.volume = volume
        self.mute = mute
        self.playlist = playlist
        self.playlistIndex = playlistIndex
    }
}

struct PlayerState {
    static let empty = PlayerState(track: nil, state: .NoMedia, position: Duration.Zero, volume: VolumeValue.Default, mute: false, playlist: [], playlistIndex: nil)
    var track: Track?
    var state: PlaybackState
    var position: Duration
    var volume: VolumeValue
    var mute: Bool
    var playlist: [Track]
    var playlistIndex: Int?
    var isPlaying: Bool { get { return state == .Playing } }
}
