//
//  Endpoint.swift
//  MusicPimp
//
//  Created by Michael Skogberg on 03/05/15.
//  Copyright (c) 2015 Skogberg Labs. All rights reserved.
//

import Foundation

class Endpoint: Printable {
    static let Local = Endpoint(id: "local", serverType: ServerTypes.Local, name: "this device", ssl: false, address: "localhost", port: 1234, username: "top", password: "secret")
    
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
    init(id: String, cloudID: String, username: String, password: String) {
        self.id = id
        self.serverType = ServerTypes.Cloud
        self.name = cloudID
        self.ssl = true
        self.address = "cloud.musicpimp.org"
        self.port = 443
        self.username = username
        self.password = password
    }
    
    // TODO polymorphism
    
    var authHeader: String {
        get {
            if serverType.isCloud {
                return HttpClient.authHeader("Pimp", unencoded: "\(name):\(username):\(password)")
            } else {
                return HttpClient.authHeader("Basic", unencoded: "\(username):\(password)")
            }
        }
    }
    var authQueryString: String {
        get {
            if serverType.isCloud {
                return "s=\(name)&u=\(username)&p=\(password)"
            } else {
                return "u=\(username)&p=\(password)"
            }
        }
    }
    
    var description: String { get { return "Endpoint \(name) at \(username)@\(httpBaseUrl)" } }
    
    var httpProto: String { get { return ssl ? "https" : "http" } }
    var wsProto: String { get { return ssl ? "wss" : "ws" } }
    
    var httpBaseUrl: String { get { return "\(httpProto)://\(address):\(port)" } }
    var wsBaseUrl: String { get { return "\(wsProto)://\(address):\(port)" } }
}
