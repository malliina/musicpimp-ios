//
//  PimpJson.swift
//  MusicPimp
//
//  Created by Michael Skogberg on 08/05/15.
//  Copyright (c) 2015 Skogberg Labs. All rights reserved.
//

import Foundation

open class PimpJson {
    public static let sharedInstance = PimpJson()
    
    static let ID = "id", SERVER_TYPE = "serverType", NAME = "name", PROTO = "proto", ADDRESS = "address", PORT = "port", USERNAME = "username", PASSWORD = "password", SSL = "ssl"
    
    static let RELATIVE_PATH = "relativePath", DESTINATION_URL = "destinationUrl", TASK = "task", TASKS = "tasks", SESSION = "session", SESSIONS = "sessions"
    
    func jsonStringified(_ e: Endpoint) -> String? {
        return Json.stringifyObject(toJson(e))
    }
    
    func toJson(_ e: Endpoint) -> [String: AnyObject] {
        return [
            PimpJson.ID: e.id as AnyObject,
//            PimpJson.CLOUD_ID: e.cl
            PimpJson.SERVER_TYPE: e.serverType.name as AnyObject,
            PimpJson.NAME: e.name as AnyObject,
            PimpJson.SSL: e.ssl as AnyObject,
            PimpJson.ADDRESS: e.address as AnyObject,
            PimpJson.PORT:  e.port as AnyObject,
            PimpJson.USERNAME: e.username as AnyObject,
            PimpJson.PASSWORD: e.password as AnyObject
        ]
    }
    
    open func toJson(_ tasks: [Int: DownloadInfo]) -> [String: AnyObject] {
        let tasksArray = tasks.map({ (e) -> [String: AnyObject] in
            let (key, value) = e
            var obj = self.toJson(value)
            obj[PimpJson.TASK] = key as AnyObject?
            return obj
        })
        return [ PimpJson.TASKS: tasksArray as AnyObject ]
    }
    
    func toJson(_ di: DownloadInfo) -> [String: AnyObject] {
        return [
            PimpJson.RELATIVE_PATH: di.relativePath as AnyObject,
            PimpJson.DESTINATION_URL: di.destinationURL.absoluteString as AnyObject
        ]
    }
    
    open func asTasks(_ dict: [String: AnyObject]) -> [Int: DownloadInfo]? {
        let arr: AnyObject? = dict[PimpJson.TASKS]
        if let ts = arr as? [[String: AnyObject]] {
            return Dictionary(ts.flatMapOpt(asDownloadInfo))
        }
        return nil
    }
    
    func asDownloadInfo(_ dict: [String: AnyObject]) -> (Int, DownloadInfo)? {
        if let relPath = dict[PimpJson.RELATIVE_PATH] as? String,
            let dest = dict[PimpJson.DESTINATION_URL] as? String,
            let destURL = URL(string: dest),
            let task = dict[PimpJson.TASK] as? Int {
                return (task, DownloadInfo(relativePath: relPath, destinationURL: destURL as DestinationURL))
        }
        return nil
    }
    
    func asEndpoint(_ dict: NSDictionary) -> Endpoint? {
        if let id = dict[PimpJson.ID] as? String,
            let serverTypeName = dict[PimpJson.SERVER_TYPE] as? String,
            let serverType = ServerTypes.fromName(serverTypeName),
            let name = dict[PimpJson.NAME] as? String,
            let ssl = dict[PimpJson.SSL] as? Bool,
            let address = dict[PimpJson.ADDRESS] as? String,
            let port = dict[PimpJson.PORT] as? Int,
            let user = dict[PimpJson.USERNAME] as? String,
            let pass = dict[PimpJson.PASSWORD] as? String {
            return Endpoint(id: id, serverType: serverType, name: name, ssl: ssl, address: address, port: port, username: user, password: pass)
            }
        return nil
    }
}

