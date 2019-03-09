//
//  PimpPlaylist.swift
//  MusicPimp
//
//  Created by Michael Skogberg on 23/05/15.
//  Copyright (c) 2015 Skogberg Labs. All rights reserved.
//

import Foundation

class PimpPlaylist: BasePlaylist, PlaylistType {
    let ResetPlaylist = "reset_playlist"
    let socket: PimpSocket
    
    init(socket: PimpSocket) {
        self.socket = socket
    }
    
    func skip(_ index: Int) -> ErrorMessage? {
        return socket.send(IntPayload(skip: index))
    }
    
    func add(_ track: Track) -> ErrorMessage? {
        return socket.send(AddTrackPayload(cmd: JsonKeys.ADD, track: track.id))
    }
    
    func add(_ tracks: [Track]) -> [ErrorMessage] {
        return tracks.flatMapOpt { (track) -> ErrorMessage? in
            add(track)
        }
    }
    
    func removeIndex(_ index: Int) -> ErrorMessage? {
        return socket.send(IntPayload(removeAt: index))
    }
    
    func move(_ src: Int, dest: Int) -> ErrorMessage? {
        return socket.send(MoveTrack(cmd: JsonKeys.Move, from: src, to: dest))
    }
    
    func reset(_ index: Int?, tracks: [Track]) -> ErrorMessage? {
        return socket.send(ResetPlaylistPayload(cmd: ResetPlaylist, index: index ?? -1, tracks: tracks.map { $0.id }))
    }
}
