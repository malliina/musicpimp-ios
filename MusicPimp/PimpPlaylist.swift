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
    func skip(index: Int) {1
        socket.send(PimpEndpoint.valuedCommand(JsonKeys.SKIP, value: index))
        //helper.postValued(JsonKeys.SKIP, value: index)
    }
    func add(track: Track) {
        let payload = [
            JsonKeys.CMD: JsonKeys.ADD,
            JsonKeys.TRACK: track.id
        ]
        socket.send(payload)
    }
    func add(tracks: [Track]) {
        for track in tracks {
            add(track)
        }
    }
    func removeIndex(index: Int) {
        let payload = PimpEndpoint.valuedCommand(JsonKeys.REMOVE, value: index)
        socket.send(payload)
    }
}
