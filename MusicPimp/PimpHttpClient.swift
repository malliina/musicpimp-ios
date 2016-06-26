//
//  PimpHttpClient.swift
//  MusicPimp
//
//  Created by Michael Skogberg on 21/03/15.
//  Copyright (c) 2015 Skogberg Labs. All rights reserved.
//

import Foundation


class Endpoints {
    static let
    PING = "/ping",
    PING_AUTH = "/pingauth",
    FOLDERS = "/folders",
    PLAYBACK = "/playback",
    WS_PLAYBACK = "/ws/playback",
    SEARCH = "/search",
    PLAYLISTS = "/playlists",
    PLAYLIST = "/playlist",
    PLAYLIST_DELETE = "/playlists/delete",
    ALARMS = "/alarms",
    ALARMS_ADD = "/alarms/editor/add",
    Popular = "/player/popular",
    Recent = "/player/recent"
}

class PimpHttpClient: HttpClient {
    let baseURL: String
    let defaultHeaders: [String: String]
    let postHeaders: [String: String]
    
    static let PIMP_VERSION_18 = "application/vnd.musicpimp.v18+json"
    
    init(baseURL: String, authValue: String) {
        if(baseURL.endsWith("/")) {
            self.baseURL = baseURL.dropLast()
        } else {
            self.baseURL = baseURL
        }
        let headers = [
            HttpClient.AUTHORIZATION: authValue,
            HttpClient.ACCEPT: PimpHttpClient.PIMP_VERSION_18
        ]
        self.defaultHeaders = headers
        var postHeaders = headers
        postHeaders.updateValue(HttpClient.JSON, forKey: HttpClient.CONTENT_TYPE)
        self.postHeaders = postHeaders
    }
    
    func pingAuth(onError: PimpError -> Void, f: Version -> Void) {
        pimpGetParsed(Endpoints.PING_AUTH, parse: parseVersion, f: f, onError: onError)
    }
    
    func pimpGetParsed<T>(resource: String, parse: AnyObject -> T?, f: T -> Void, onError: PimpError -> Void) {
        pimpGet(resource, f: {
            data -> Void in
            if let obj: AnyObject = Json.asJson(data) {
                if let parsed: T = parse(obj) {
                    f(parsed)
                } else {
                    onError(.ParseError)
                    self.log("Parse error.")
                }
            } else {
                onError(.ParseError)
                self.log("Not JSON: \(data)")
            }
        }, onError: onError)
    }
    
    func pimpGet(resource: String, f: NSData -> Void, onError: PimpError -> Void) {
        let url = baseURL + resource
        log(url)
        self.get(
            url,
            headers: defaultHeaders,
            onResponse: { (data, response) -> Void in
                self.responseHandler(resource, data: data, response: response, f: f, onError: onError)
            },
            onError: { (err) -> Void in
                onError(.NetworkFailure(err))
            })
    }
    
    func pimpPost(resource: String, payload: [String: AnyObject], f: NSData -> Void, onError: PimpError -> Void) {
        self.postJSON(
            baseURL + resource,
            headers: postHeaders,
            payload: payload,
            onResponse: { (data, response) -> Void in
                self.responseHandler(resource, data: data, response: response, f: f, onError: onError)
            },
            onError: { (err) -> Void in
                onError(.NetworkFailure(err))
            })
    }
    
    func responseHandler(resource: String, data: NSData, response: NSHTTPURLResponse, f: NSData -> Void, onError: PimpError -> Void) {
        let statusCode = response.statusCode
        let isStatusOK = (statusCode >= 200) && (statusCode < 300)
        if isStatusOK {
            f(data)
        } else {
            var errorMessage: String? = nil
            if let json = Json.asJson(data) as? NSDictionary {
                errorMessage = json[JsonKeys.ERROR] as? String
            }
            onError(.ResponseFailure(resource, statusCode, errorMessage))
        }
    }
    
    func onRequestError(data: NSData, error: NSError) -> Void {
        log("Error: \(data)")
    }
    
    func onMusicFolder(f: MusicFolder) -> Void {
        log("Tracks: \(f.tracks.count)")
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
    
    func log(s: String) {
        Log.info(s)
    }
}