//
//  PimpJson.swift
//  MusicPimp
//
//  Created by Michael Skogberg on 08/05/15.
//  Copyright (c) 2015 Skogberg Labs. All rights reserved.
//

import Foundation

public class PimpJson {
    public static let sharedInstance = PimpJson()
    
    static let ID = "id", SERVER_TYPE = "serverType", NAME = "name", PROTO = "proto", ADDRESS = "address", PORT = "port", USERNAME = "username", PASSWORD = "password", SSL = "ssl"
    
    static let RELATIVE_PATH = "relativePath", DESTINATION_URL = "destinationUrl", TASK = "task", TASKS = "tasks", SESSION = "session", SESSIONS = "sessions"
    
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
    
    public func toJson(tasks: [Int: DownloadInfo]) -> [String: AnyObject] {
        let tasksArray = tasks.map({ (e) -> [String: AnyObject] in
            let (key, value) = e
            var obj = self.toJson(value)
            obj[PimpJson.TASK] = key
            return obj
        })
        return [ PimpJson.TASKS: tasksArray ]
    }
    
    func toJson(di: DownloadInfo) -> [String: AnyObject] {
        return [
            PimpJson.RELATIVE_PATH: di.relativePath,
            PimpJson.DESTINATION_URL: di.destinationURL.absoluteString ?? ""
        ]
    }
    
    public func asTasks(dict: NSDictionary) -> [Int: DownloadInfo]? {
        let arr: AnyObject? = dict[PimpJson.TASKS]
        if let ts = arr as? [[String: AnyObject]] {
            return Dictionary(ts.flatMapOpt(asDownloadInfo))
        }
        return nil
    }
    
    func asDownloadInfo(dict: [String: AnyObject]) -> (Int, DownloadInfo)? {
        if let relPath = dict[PimpJson.RELATIVE_PATH] as? String,
            dest = dict[PimpJson.DESTINATION_URL] as? String,
            destURL = NSURL(string: dest),
            task = dict[PimpJson.TASK] as? Int {
                return (task, DownloadInfo(relativePath: relPath, destinationURL: destURL))
        }
        return nil
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

