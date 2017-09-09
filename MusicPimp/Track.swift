//
//  Track.swift
//  MusicPimp
//
//  Created by Michael Skogberg on 01/11/15.
//  Copyright © 2015 Skogberg Labs. All rights reserved.
//

import Foundation

open class Track: MusicItem, Hashable {
    static let empty = Track(id: "", title: "", album: "", artist: "", duration: Duration.Zero, path: "", size: StorageSize.Zero, url: URL(string: "https://www.musicpimp.org")!)
    
    let album: String
    let artist: String
    let duration: Duration
    let path: String
    let size: StorageSize
    let url: URL
    
    open var hashValue : Int { get { return self.id.hashValue } }
    
    public init(id: String, title: String, album: String, artist: String, duration: Duration, path: String, size: StorageSize, url: URL) {
        self.album = album
        self.artist = artist
        self.duration = duration
        self.path = path
        self.size = size
        self.url = url
        super.init(id: id, title: title)
    }
    
    open static func toJson(_ t: Track) -> [String: AnyObject] {
        return [
            JsonKeys.ID: t.id as AnyObject,
            JsonKeys.TITLE: t.title as AnyObject,
            JsonKeys.ARTIST: t.artist as AnyObject,
            JsonKeys.ALBUM: t.album as AnyObject,
            JsonKeys.SIZE: NSNumber(value: t.size.toBytes as Int64),
            JsonKeys.DURATION: NSNumber(value: t.duration.seconds as Int64)
        ]
    }
}

public func ==(lhs: Track, rhs: Track) -> Bool {
    return lhs.id == rhs.id
}
