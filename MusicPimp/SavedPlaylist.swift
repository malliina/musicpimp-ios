//
//  SavedPlaylist.swift
//  MusicPimp
//
//  Created by Michael Skogberg on 01/11/15.
//  Copyright © 2015 Skogberg Labs. All rights reserved.
//

import Foundation

open class SavedPlaylist {
    let id: PlaylistID?
    let name: String
    let tracks: [Track]
    
    public init(id: PlaylistID?, name: String, tracks: [Track]) {
        self.id = id
        self.name = name
        self.tracks = tracks
    }
    
    open var description: String { get { return "Playlist(\(id), \(name), \(tracks.mkString(", ")))" } }
    
    open static func toJson(_ sp: SavedPlaylist) -> [String: AnyObject] {
        let trackIDs = sp.tracks.map { $0.id }
        return [
            JsonKeys.ID: sp.id?.id as AnyObject? ?? NSNull(),
            JsonKeys.NAME: sp.name as AnyObject,
            JsonKeys.TRACKS: trackIDs as AnyObject
        ]
    }
}
