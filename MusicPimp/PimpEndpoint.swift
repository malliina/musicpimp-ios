//
//  PimpEndpoint.swift
//  MusicPimp
//
//  Created by Michael Skogberg on 24/05/15.
//  Copyright (c) 2015 Skogberg Labs. All rights reserved.
//

import Foundation

class PimpEndpoint {
    let client: PimpHttpClient
    init(client: PimpHttpClient) {
        self.client = client
    }
    func postPlayback(cmd: String) {
        let dict = simpleCommand(cmd)
        postDict(dict)
    }
    func postValued(cmd: String, value: AnyObject) {
        let dict = valuedCommand(cmd, value: value)
        postDict(dict)
    }
    func postDict(dict: [String: AnyObject]) {
        client.pimpPost(Endpoints.PLAYBACK, payload: dict, f: onSuccess, onError: onError)
    }
    func onSuccess(data: NSData) {
        
    }
    func onError(error: PimpError) {
        let str = PimpErrorUtil.stringify(error)
        Log.info("Player error: \(str)")
    }
    func simpleCommand(cmd: String) -> [String: String] {
        return [
            JsonKeys.CMD: cmd
        ]
    }
    func valuedCommand(cmd: String, value: AnyObject) -> [String: AnyObject] {
        return [
            JsonKeys.CMD: cmd,
            JsonKeys.VALUE: value
        ]
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
                                    path: Util.urlDecode(id),
                                    size: Int64(size),
                                    url: self.urlFor(id),
                                    username: client.username,
                                    password: client.password)
                            }
                        }
                    }
                }
            }
        }
        return nil
    }

    func urlFor(trackID: String) -> NSURL {
        return NSURL(string: "\(client.baseURL)/tracks/\(trackID)?u=\(client.username)&p=\(client.password)")!
    }
}