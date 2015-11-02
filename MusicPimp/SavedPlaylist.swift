//
//  SavedPlaylist.swift
//  MusicPimp
//
//  Created by Michael Skogberg on 01/11/15.
//  Copyright © 2015 Skogberg Labs. All rights reserved.
//

import Foundation

public class SavedPlaylist {
    let id: PlaylistID?
    let name: String
    let tracks: [Track]
    
    public init(id: PlaylistID?, name: String, tracks: [Track]) {
        self.id = id
        self.name = name
        self.tracks = tracks
    }
    
    public var description: String { get { return "Playlist(\(id), \(name), \(tracks.mkString(", ")))" } }
    
    public static func toJson(sp: SavedPlaylist) -> [String: AnyObject] {
        let trackIDs = sp.tracks.map { $0.id }
        return [
            JsonKeys.ID: sp.id?.id ?? NSNull(),
            JsonKeys.NAME: sp.name,
            JsonKeys.TRACKS: trackIDs
        ]
    }
}
