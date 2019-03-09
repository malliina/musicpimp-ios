//
//  SavedPlaylist.swift
//  MusicPimp
//
//  Created by Michael Skogberg on 01/11/15.
//  Copyright © 2015 Skogberg Labs. All rights reserved.
//

import Foundation

struct SavedPlaylists: Codable {
    let playlists: [SavedPlaylist]
}

struct SavedPlaylistResponse: Codable {
    let playlist: SavedPlaylist
}

struct SavedPlaylist: Codable {
    let id: PlaylistID?
    let name: String
    let trackCount: Int
    let duration: Duration
    let tracks: [Track]
    
    func strip() -> SavedPlaylistStripped {
        return SavedPlaylistStripped(id: id, name: name, trackCount: trackCount, duration: duration, tracks: tracks.map { $0.id })
    }
}

struct SavePlaylistPayload: Codable {
    let playlist: SavedPlaylistStripped
}

struct SavedPlaylistStripped: Codable {
    let id: PlaylistID?
    let name: String
    let trackCount: Int
    let duration: Duration
    let tracks: [TrackID]
}
