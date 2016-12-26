//
//  LocalPlaylist.swift
//  MusicPimp
//
//  Created by Michael Skogberg on 25/04/15.
//  Copyright (c) 2015 Skogberg Labs. All rights reserved.
//

import Foundation

class LocalPlaylist: BasePlaylist, PlaylistType {
    static let sharedInstance = LocalPlaylist()
    
    fileprivate var ts: [Track] = []
    fileprivate var p: Int? = nil
    
    static func newPlaylistIndex(_ current: Int, src: Int, dest: Int) -> Int {
        if src == current {
            return dest
        } else if src < current && dest >= current {
            return current - 1
        } else if src > current && dest <= current {
            return current + 1
        } else {
            return current
        }
    }

    func current() -> Playlist {
        return Playlist(tracks: ts, index: p)
    }
    
    func position() -> Int? {
        return p
    }
    
    func currentTrack() -> Track? {
        if let pos = position() {
            return trackAt(pos)
        }
        return nil
    }
    
    func next() -> Track? {
        return positionTransform({$0 + 1})
    }
    
    func prev() -> Track? {
        return positionTransform({$0 - 1})
    }
    
    func skip(_ index: Int) -> Track? {
        return positionTransform({ pos in index })
    }
    
    func tracks() -> [Track] {
        return ts
    }
    
    func reset(_ track: Track) {
        reset([track])
    }
    
    func reset(_ tracks: [Track]) {
        ts = tracks
        p = ts.count > 0 ? 0 : nil
        playlistUpdated()
        indexEvent.raise(p)
        onTracksAdded(tracks)
    }
    
    func add(_ track: Track) -> ErrorMessage? {
        return add([track]).headOption()
    }
    
    func add(_ tracks: [Track]) -> [ErrorMessage] {
        ts.append(contentsOf: tracks)
        playlistUpdated()
        onTracksAdded(tracks)
        return []
    }
    
    func move(_ src: Int, dest: Int) -> ErrorMessage? {
        if src != dest {
            //let newTracks = Arrays.move(src, destIndex: dest, xs: ts)
            ts = Arrays.move(src, destIndex: dest, xs: ts)
            if let p = p {
                self.p = LocalPlaylist.newPlaylistIndex(p, src: src, dest: dest)
            }
            playlistUpdated()
        }
        return nil
    }
    
    fileprivate func onTracksAdded(_ ts: [Track]) {
        for track in ts {
            trackAdded.raise(track)
        }
    }
    
    func removeIndex(_ index: Int) -> ErrorMessage? {
        ts.remove(at: index)
        if let position = position() {
            if position == index {
                p = nil
            } else if position > index {
                p = position - 1
            }
        }
        playlistUpdated()
        return nil
    }
    
    fileprivate func playlistUpdated() {
        playlistEvent.raise(Playlist(tracks: ts, index: p))
    }
    
    fileprivate func positionTransform(_ f: (Int) -> Int) -> Track? {
        var nextPos = 0
        if let currentPos = p {
            nextPos = f(currentPos)
        }
        if let track = trackAt(nextPos) {
            p = nextPos
            indexEvent.raise(p)
            return track
        }
        return nil
    }
    
    fileprivate func trackAt(_ pos: Int) -> Track? {
        if pos >= 0 && pos < ts.count {
            return ts[pos]
        }
        return nil
    }
}
