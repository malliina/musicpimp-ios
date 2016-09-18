//
//  PimpPlaylist.swift
//  MusicPimp
//
//  Created by Michael Skogberg on 23/05/15.
//  Copyright (c) 2015 Skogberg Labs. All rights reserved.
//

import Foundation

class PimpPlaylist: BasePlaylist, PlaylistType {
    //let client: PimpHttpClient
    //let helper: PimpEndpoint
    let socket: PimpSocket
    
    init(socket: PimpSocket) {
        self.socket = socket
        //self.client = client
        //self.helper = PimpEndpoint(endpoint: endpoint, client: client)
    }
    func skip(_ index: Int) {
        socket.send(PimpEndpoint.valuedCommand(JsonKeys.SKIP, value: index as AnyObject))
        //helper.postValued(JsonKeys.SKIP, value: index)
    }
    
    func add(_ track: Track) {
        let payload = [
            JsonKeys.CMD: JsonKeys.ADD,
            JsonKeys.TRACK: track.id
        ]
        socket.send(payload as [String : AnyObject])
    }
    
    func add(_ tracks: [Track]) {
        for track in tracks {
            add(track)
        }
    }
    
    func removeIndex(_ index: Int) {
        let payload = PimpEndpoint.valuedCommand(JsonKeys.REMOVE, value: index as AnyObject)
        socket.send(payload)
    }
    
    func move(_ src: Int, dest: Int) {
        let payload: [String: AnyObject] = [
            JsonKeys.CMD: JsonKeys.Move as AnyObject,
            JsonKeys.From: src as AnyObject,
            JsonKeys.To: dest as AnyObject
        ]
        socket.send(payload)
    }
}
