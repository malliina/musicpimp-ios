//
//  Endpoint.swift
//  MusicPimp
//
//  Created by Michael Skogberg on 03/05/15.
//  Copyright (c) 2015 Skogberg Labs. All rights reserved.
//

import Foundation

class Endpoint: Printable {
    let id: String
    let serverType: ServerType
    let name: String
    let proto: Protocol
    let address: String
    let port: Int
    let username: String
    let password: String
    
    init(id: String, serverType: ServerType, name: String, proto: Protocol, address: String, port: Int, username: String, password: String) {
        self.id = id
        self.serverType = serverType
        self.name = name
        self.proto = proto
        self.address = address
        self.port = port
        self.username = username
        self.password = password
    }
    
    var description: String { get { return "Endpoint \(name) at \(username)@\(proto.rawValue)://\(address):\(port)" } }
}
