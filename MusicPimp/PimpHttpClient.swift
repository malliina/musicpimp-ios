//
//  PimpHttpClient.swift
//  MusicPimp
//
//  Created by Michael Skogberg on 21/03/15.
//  Copyright (c) 2015 Skogberg Labs. All rights reserved.
//

import Foundation

class Playlist {
    let tracks: [Track]
    let index: Int?
    init(tracks: [Track], index: Int?) {
        self.tracks = tracks
        self.index = index
    }
    static let empty = Playlist(tracks: [], index: nil)
}
class MusicItem {
    let id: String
    let title: String
    init(id: String, title: String) {
        self.id = id
        self.title = title
    }
}

class Folder: MusicItem {
    let path: String
    init(id: String, title: String, path: String) {
        self.path = path
        super.init(id: id, title: title)
    }
}

class Track: MusicItem {
    let album: String
    let artist: String
    let duration: Int
    let size: Int
    let url: String
    let username: String
    let password: String

    init(id: String, title: String, album: String, artist: String, duration: Int, size: Int, url: String, username: String, password: String) {
        self.album = album
        self.artist = artist
        self.duration = duration
        self.size = size
        self.url = url
        self.username = username
        self.password = password
        super.init(id: id, title: title)
    }
}

struct MusicFolder {
    let folder: Folder
    let folders: [Folder]
    let tracks: [Track]
}

struct Version {
    let version: String
}

class PimpHttpClient: HttpClient {
    class JsonKeys {
        static let
        TITLE = "title",
        FOLDER = "folder",
        FOLDERS = "folders",
        TRACKS = "tracks",
        ID = "id",
        ARTIST = "artist",
        ALBUM = "album",
        SIZE = "size",
        DURATION = "duration",
        PATH = "path",
        VERSION = "version"
    }
    class Endpoints {
        static let
        PING = "/ping",
        PING_AUTH = "/pingauth",
        FOLDERS = "/folders"
    }
    
    let baseURL: String
    let username: String
    let password: String
    let defaultHeaders: Dictionary<String,String>
    
    init(baseURL: String, username: String, password: String) {
        if(baseURL.endsWith("/")) {
            self.baseURL = baseURL.dropLast()
        } else {
            self.baseURL = baseURL
        }
        self.username = username
        self.password = password
        let authValue = HttpClient.basicAuthValue(username, password: password)
        self.defaultHeaders = [HttpClient.AUTHORIZATION: authValue, HttpClient.ACCEPT: HttpClient.JSON]
    }
    
    func test() {
        ping()
    }
    func ping() {
        pimpGet(Endpoints.PING, f: {
            (r) -> Void in
            self.log("Ping: \(r)")
        })
    }
    func pingAuth() {
        pimpGetParsed(Endpoints.PING_AUTH, parse: parseVersion, f: {
            (version) -> Void in
            self.log("Version: \(version.version)")
        })
    }
    func rootFolder(f: MusicFolder -> Void) {
        pimpGetParsed(Endpoints.FOLDERS, parse: parseMusicFolder, f: f)
    }
    
    func folder(id: String, f: MusicFolder -> Void) {
        pimpGetParsed("\(Endpoints.FOLDERS)/\(id)", parse: parseMusicFolder, f: f)
    }
    func tracks(id: String, f: [Track] -> Void) {
        tracksInner(id,  others: [], acc: [], f: f)
    }
    private func tracksInner(id: String, others: [String], acc: [Track], f: [Track] -> Void){
        folder(id) { result in
            let subIDs = result.folders.map { $0.id }
            let remaining = others + subIDs
            let newAcc = acc + result.tracks
            if let head = remaining.first {
                let tail = remaining.tail()
                self.tracksInner(head, others: tail, acc: newAcc, f: f)
            } else {
                f(newAcc)
            }
        }
    }
    
    func pimpStatus() {
        rootFolder(onMusicFolder)
    }
    func urlFor(trackID: String) -> String {
        return "\(self.baseURL)/tracks/\(trackID)"
    }
    
    func pimpGetParsed<T>(resource: String, parse: AnyObject -> T?, f: T -> Void) {
        pimpGet(resource, f: {
            data -> Void in
            var error: NSError?
            let anyObj: AnyObject? = Json.asJson(data, error: &error)
            if let obj: AnyObject = anyObj {
                if let parsed: T = parse(obj) {
                    f(parsed)
                } else {
                    self.log("Parse error.")
                }
            } else {
                self.log("Not JSON: \(data)")
            }
        })
    }
    
    
    func pimpGet(resource: String, f: NSData -> Void) {
        log(resource)
        self.get(
            baseURL + resource,
            headers: defaultHeaders,
            onResponse: { (data, response) -> Void in
                //let str = NSString(data: data, encoding: NSUTF8StringEncoding)
                let statusCode = response.statusCode
                let isStatusOK = (statusCode >= 200) && (statusCode < 300)
                if isStatusOK {
                    f(data)
                } else {
                    self.log("Invalid status code in response: \(statusCode)")
                }
                //self.log("Response handled.")
            },
            onError: onRequestError)
    }

    func onRequestError(data: NSData, error: NSError) -> Void {
        log("Error: \(data)")
    }
    func onMusicFolder(f: MusicFolder) -> Void {
        log("Tracks: \(count(f.tracks))")
    }
    
    func parseVersion(obj: AnyObject) -> Version? {
        if let dict = obj as? NSDictionary {
            if let version = dict[JsonKeys.VERSION] as? String {
                return Version(version: version)
          }
        }
        log("Unable to get status")
        return nil
    }
    func parseMusicFolder(obj: AnyObject) -> MusicFolder? {
        if let dict = obj as? NSDictionary {
            if let folderJSON = dict[JsonKeys.FOLDER] as? NSDictionary {
                if let foldersJSON = dict[JsonKeys.FOLDERS] as? NSArray {
                    if let tracksJSON = dict[JsonKeys.TRACKS] as? NSArray {
                        let root = parseFolder(folderJSON)!
                        let foldObjects = foldersJSON as! [NSDictionary]
                        let folders: [Folder] = foldObjects.map({(o) -> Folder in self.parseFolder(o)!})
                        let trackObjects = tracksJSON as! [NSDictionary]
                        let tracks: [Track] = trackObjects.map({(o) -> Track in self.parseTrack(o)!})
                        return MusicFolder(folder: root, folders: folders, tracks: tracks)
                    }
                }
            }
        }
        log("Unable to parse \(obj) as music folder")
        return nil
    }
    func parseTrack(obj: NSDictionary) -> Track? {
        if let id = obj[JsonKeys.ID] as? String {
            if let title = obj[JsonKeys.TITLE] as? String {
                if let artist = obj[JsonKeys.ARTIST] as? String {
                    if let album = obj[JsonKeys.ALBUM] as? String {
                        if let size = obj[JsonKeys.SIZE] as? Int {
                            if let duration = obj[JsonKeys.DURATION] as? Int {
                                return Track(
                                    id: id,
                                    title: title,
                                    album: album,
                                    artist: artist,
                                    duration: duration,
                                    size: size,
                                    url: self.urlFor(id),
                                    username: self.username,
                                    password: self.password)
                            }
                        }
                    }
                }
            }
        }
        return nil
    }
    func parseFolder(obj: NSDictionary) -> Folder? {
        if let id = obj[JsonKeys.ID] as? String {
            if let title = obj[JsonKeys.TITLE] as? String {
                if let path = obj[JsonKeys.PATH] as? String {
                    return Folder(
                        id: id,
                        title: title,
                        path: path)
                }
            }
        }
        return nil
    }
    
    func log(s: String) {
        Log.info(s)
    }
}