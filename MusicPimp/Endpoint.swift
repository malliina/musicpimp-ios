//
//  Endpoint.swift
//  MusicPimp
//
//  Created by Michael Skogberg on 03/05/15.
//  Copyright (c) 2015 Skogberg Labs. All rights reserved.
//

import Foundation

class Endpoint: CustomStringConvertible {
    static let Local = Endpoint(id: "local", serverType: ServerTypes.Local, name: "this device", ssl: false, address: "localhost", port: 1234, username: "top", password: "secret")!
    
    let id: String
    let serverType: ServerType
    let name: String
    let ssl: Bool
    let address: String
    let port: Int
    let username: String
    let password: String
    let httpBaseUrl: URL
    let wsBaseUrl: URL
    
    init?(id: String, serverType: ServerType, name: String, ssl: Bool, address: String, port: Int, username: String, password: String) {
        self.id = id
        self.serverType = serverType
        self.name = name
        self.ssl = ssl
        self.address = address
        self.port = port
        self.username = username
        self.password = password
        let httpProto = ssl ? "https" : "http"
        let wsProto = ssl ? "wss" : "ws"
        let httpUrl = URL(string: "\(httpProto)://\(address):\(port)")
        let wsUrl = URL(string: "\(wsProto)://\(address):\(port)")
        if let httpUrl = httpUrl, let wsUrl = wsUrl {
            self.httpBaseUrl = httpUrl
            self.wsBaseUrl = wsUrl
        } else {
            return nil
        }
    }
    
    convenience init?(id: String, cloudID: String, username: String, password: String) {
        self.init(id: id, serverType: ServerTypes.Cloud, name: cloudID, ssl: true, address: "cloud.musicpimp.org", port: 443, username: username, password: password)
    }
    
//    convenience init?(id: String, cloudID: String, username: String, password: String) {
//        self.init(id: id, serverType: ServerTypes.Cloud, name: cloudID, ssl: false, address: "10.0.0.21", port: 9000, username: username, password: password)
//    }
    
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
            let unencoded = serverType.isCloud ? "s=\(name)&u=\(username)&p=\(password)" : "u=\(username)&p=\(password)"
            return unencoded.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed) ?? unencoded
        }
    }
    
    var description: String { get { return "Endpoint \(name) at \(username)@\(httpBaseUrl)" } }

    var supportsAlarms: Bool { get { return serverType == ServerTypes.MusicPimp || serverType == ServerTypes.Cloud } }
}
