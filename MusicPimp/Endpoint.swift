//
//  Endpoint.swift
//  MusicPimp
//
//  Created by Michael Skogberg on 03/05/15.
//  Copyright (c) 2015 Skogberg Labs. All rights reserved.
//

import Foundation

class Endpoint: Printable {
    static let Local = Endpoint(id: "local", serverType: .MusicPimp, name: "this device", ssl: false, address: "localhost", port: 1234, username: "top", password: "secret")
    
    let id: String
    let serverType: ServerType
    let name: String
    let ssl: Bool
    let address: String
    let port: Int
    let username: String
    let password: String
    
    init(id: String, serverType: ServerType, name: String, ssl: Bool, address: String, port: Int, username: String, password: String) {
        self.id = id
        self.serverType = serverType
        self.name = name
        self.ssl = ssl
        self.address = address
        self.port = port
        self.username = username
        self.password = password
    }
    
    var description: String { get { return "Endpoint \(name) at \(username)@\(httpBaseUrl)" } }
    
    var httpProto: String { get { return ssl ? "https" : "http" } }
    var wsProto: String { get { return ssl ? "wss" : "ws" } }
    
    var httpBaseUrl: String { get { return "\(httpProto)://\(address):\(port)" } }
    var wsBaseUrl: String { get { return "\(wsProto)://\(address):\(port)" } }
}
