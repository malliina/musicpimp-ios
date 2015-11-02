//
//  Track.swift
//  MusicPimp
//
//  Created by Michael Skogberg on 01/11/15.
//  Copyright © 2015 Skogberg Labs. All rights reserved.
//

import Foundation

public class Track: MusicItem, Hashable {
    let album: String
    let artist: String
    let duration: Duration
    let path: String
    let size: StorageSize
    let url: NSURL
    
    public var hashValue : Int { get { return self.id.hashValue } }
    
    public init(id: String, title: String, album: String, artist: String, duration: Duration, path: String, size: StorageSize, url: NSURL) {
        self.album = album
        self.artist = artist
        self.duration = duration
        self.path = path
        self.size = size
        self.url = url
        super.init(id: id, title: title)
    }
    
    public static func toJson(t: Track) -> [String: AnyObject] {
        return [
            JsonKeys.ID: t.id,
            JsonKeys.TITLE: t.title,
            JsonKeys.ARTIST: t.artist,
            JsonKeys.ALBUM: t.album,
            JsonKeys.SIZE: NSNumber(longLong: t.size.toBytes),
            JsonKeys.DURATION: NSNumber(longLong: t.duration.seconds)
        ]
    }
}

public func ==(lhs: Track, rhs: Track) -> Bool {
    return lhs.id == rhs.id
}
