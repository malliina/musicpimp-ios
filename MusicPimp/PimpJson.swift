//
//  PimpJson.swift
//  MusicPimp
//
//  Created by Michael Skogberg on 08/05/15.
//  Copyright (c) 2015 Skogberg Labs. All rights reserved.
//

import Foundation
class PimpJson {
    static let sharedInstance = PimpJson()
    
    static let ID = "id", SERVER_TYPE = "serverType", NAME = "name", PROTO = "proto", ADDRESS = "address", PORT = "port", USERNAME = "username", PASSWORD = "password", SSL = "ssl"
    
    func jsonStringified(e: Endpoint) -> String? {
        return Json.stringifyObject(toJson(e))
    }
    
    func toJson(e: Endpoint) -> [String: AnyObject] {
        return [
            PimpJson.ID: e.id,
//            PimpJson.CLOUD_ID: e.cl
            PimpJson.SERVER_TYPE: e.serverType.name,
            PimpJson.NAME: e.name,
            PimpJson.SSL: e.ssl,
            PimpJson.ADDRESS: e.address,
            PimpJson.PORT:  e.port,
            PimpJson.USERNAME: e.username,
            PimpJson.PASSWORD: e.password
        ]
    }
    
    func asEndpoint(dict: NSDictionary) -> Endpoint? {
        if let id = dict[PimpJson.ID] as? String,
            serverTypeName = dict[PimpJson.SERVER_TYPE] as? String,
            serverType = ServerTypes.fromName(serverTypeName),
            name = dict[PimpJson.NAME] as? String,
            ssl = dict[PimpJson.SSL] as? Bool,
            address = dict[PimpJson.ADDRESS] as? String,
            port = dict[PimpJson.PORT] as? Int,
            user = dict[PimpJson.USERNAME] as? String,
            pass = dict[PimpJson.PASSWORD] as? String {
            return Endpoint(id: id, serverType: serverType, name: name, ssl: ssl, address: address, port: port, username: user, password: pass)
            }
        return nil
    }
}

