//
//  PimpPlaylist.swift
//  MusicPimp
//
//  Created by Michael Skogberg on 23/05/15.
//  Copyright (c) 2015 Skogberg Labs. All rights reserved.
//

import Foundation

class PimpPlaylist: BasePlaylist, PlaylistType {
    let socket: PimpSocket
    
    init(socket: PimpSocket) {
        self.socket = socket
    }
    func skip(_ index: Int) -> ErrorMessage? {
        return socket.send(PimpEndpoint.valuedCommand(JsonKeys.SKIP, value: index as AnyObject))
    }
    
    func add(_ track: Track) -> ErrorMessage? {
        let payload = [
            JsonKeys.CMD: JsonKeys.ADD,
            JsonKeys.TRACK: track.id
        ]
        return socket.send(payload as [String : AnyObject])
    }
    
    func add(_ tracks: [Track]) -> [ErrorMessage] {
        return tracks.flatMapOpt { (track) -> ErrorMessage? in
            add(track)
        }
    }
    
    func removeIndex(_ index: Int) -> ErrorMessage? {
        let payload = PimpEndpoint.valuedCommand(JsonKeys.REMOVE, value: index as AnyObject)
        return socket.send(payload)
    }
    
    func move(_ src: Int, dest: Int) -> ErrorMessage? {
        let payload: [String: AnyObject] = [
            JsonKeys.CMD: JsonKeys.Move as AnyObject,
            JsonKeys.From: src as AnyObject,
            JsonKeys.To: dest as AnyObject
        ]
        return socket.send(payload)
    }
}
