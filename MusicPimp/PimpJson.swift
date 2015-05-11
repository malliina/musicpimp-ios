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
    
    static let ID = "id", SERVER_TYPE = "serverType", NAME = "name", PROTO = "proto", ADDRESS = "address", PORT = "port", USERNAME = "username", PASSWORD = "password"
    
    func jsonStringified(e: Endpoint) -> String? {
        return stringify(toJson(e))
    }
    
    func toJson(e: Endpoint) -> [String: AnyObject] {
        return [
            PimpJson.ID: e.id,
            PimpJson.SERVER_TYPE: e.serverType.rawValue,
            PimpJson.NAME: e.name,
            PimpJson.PROTO: e.proto.rawValue,
            PimpJson.ADDRESS: e.address,
            PimpJson.PORT:  e.port,
            PimpJson.USERNAME: e.username,
            PimpJson.PASSWORD: e.password
        ]
    }
    
    func asEndpoint(dict: NSDictionary) -> Endpoint? {
        if let id = dict[PimpJson.ID] as? String {
            if let serverType = dict[PimpJson.SERVER_TYPE] as? String {
                if let name = dict[PimpJson.NAME] as? String {
                    if let proto = dict[PimpJson.PROTO] as? String {
                        if let address = dict[PimpJson.ADDRESS] as? String {
                            if let port = dict[PimpJson.PORT] as? Int {
                                if let user = dict[PimpJson.USERNAME] as? String {
                                    if let pass = dict[PimpJson.PASSWORD] as? String {
                                        return Endpoint(id: id, serverType: ServerType(rawValue: serverType)!, name: name, proto: Protocol(rawValue: proto)!, address: address, port: port, username: user, password: pass)
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
        return nil
    }
    
    func stringify(value: AnyObject, prettyPrinted: Bool = true) -> String? {
        var options = prettyPrinted ? NSJSONWritingOptions.PrettyPrinted : nil
        if NSJSONSerialization.isValidJSONObject(value) {
            if let data = NSJSONSerialization.dataWithJSONObject(value, options: options, error: nil) {
                return NSString(data: data, encoding: NSUTF8StringEncoding) as String?
            }
        }
        return nil
    }

}
