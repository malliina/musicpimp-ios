//
//  Endpoint.swift
//  MusicPimp
//
//  Created by Michael Skogberg on 03/05/15.
//  Copyright (c) 2015 Skogberg Labs. All rights reserved.
//

import Foundation

struct EndpointsContainer: Codable {
    let endpoints: [Endpoint]
}

struct Endpoint: Codable, CustomStringConvertible {
    static let Local = Endpoint(id: "local", serverType: ServerType.local, name: "this device", ssl: false, address: "localhost", port: 1234, username: "top", password: "secret")
    
    static func cloud(id: String, cloudID: String, username: String, password: String) -> Endpoint {
        Endpoint(id: id, serverType: ServerType.cloud, name: cloudID, ssl: true, address: "cloud.musicpimp.org", port: 443, username: username, password: password)
    }
    
    let id: String
    let serverType: ServerType
    let name: String
    let ssl: Bool
    let address: String
    let port: Int
    let username: String
    let password: String
    
    var httpProto: String { ssl ? "https" : "http" }
    var wsProto: String { ssl ? "wss" : "ws" }
    var httpBaseUrl: URL { URL(string: "\(httpProto)://\(address):\(port)")! }
    var wsBaseUrl: URL { URL(string: "\(wsProto)://\(address):\(port)")! }
    
    var authHeader: String {
        get {
            if serverType.isCloud {
                return HttpClient.authHeader("Pimp", unencoded: "\(name):\(username):\(password)")
            } else {
                return HttpClient.authHeader("Basic", unencoded: "\(username):\(password)")
            }
        }
    }
    
    /// It seems like AVPlayer does not support HTTP headers, so we pass the credentials in the query string for local playback
    var authQueryString: String {
        get {
            let unencoded = serverType.isCloud ? "s=\(name)&u=\(username)&p=\(password)" : "u=\(username)&p=\(password)"
            return unencoded.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed) ?? unencoded
        }
    }

    var description: String { get { "Endpoint \(name) at \(username)@\(httpBaseUrl)" } }

    var supportsAlarms: Bool { get { serverType == ServerType.musicPimp || serverType == ServerType.cloud } }
}
