//
//  PimpStatus.swift
//  MusicPimp
//
//  Created by Michael Skogberg on 23/05/15.
//  Copyright (c) 2015 Skogberg Labs. All rights reserved.
//

import Foundation

class PlayerState {
    
    static let empty = PlayerState(track: nil, state: .NoMedia, position: 0, volume: 40, mute: false, playlist: [], playlistIndex: nil)
    
    let track: Track?
    let state: PlaybackState
    let position: Int
    let volume: Int
    let mute: Bool
    let playlist: [Track]
    let playlistIndex: Int?
    
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
