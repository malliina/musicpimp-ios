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
    let baseURL: URL
    let defaultHeaders: [String: String]
    let postHeaders: [String: String]
    
    static let PIMP_VERSION_18 = "application/vnd.musicpimp.v18+json"
    
    init(baseURL: URL, authValue: String) {
        self.baseURL = baseURL
        let headers = [
            HttpClient.AUTHORIZATION: authValue,
            HttpClient.ACCEPT: PimpHttpClient.PIMP_VERSION_18
        ]
        self.defaultHeaders = headers
        var postHeaders = headers
        postHeaders.updateValue(HttpClient.JSON, forKey: HttpClient.CONTENT_TYPE)
        self.postHeaders = postHeaders
    }
    
    func pingAuth(_ onError: @escaping (PimpError) -> Void, f: @escaping (Version) -> Void) {
        pimpGetParsed(Endpoints.PING_AUTH, parse: parseVersion, f: f, onError: onError)
    }
    
    func pimpGetParsed<T>(_ resource: String, parse: @escaping (AnyObject) -> T?, f: @escaping (T) -> Void, onError: @escaping (PimpError) -> Void) {
        pimpGet(resource, f: {
            data -> Void in
            if let obj: AnyObject = Json.asJson(data) {
                if let parsed: T = parse(obj) {
                    f(parsed)
                } else {
                    onError(.parseError)
                    self.log("Parse error.")
                }
            } else {
                onError(.parseError)
                self.log("Not JSON: \(data)")
            }
        }, onError: onError)
    }
    
    func pimpGet(_ resource: String, f: @escaping (Data) -> Void, onError: @escaping (PimpError) -> Void) {
        let url = URL(string: resource, relativeTo: baseURL)!
        log(url.absoluteString)
        self.get(
            url,
            headers: defaultHeaders,
            onResponse: { (data, response) -> Void in
                self.responseHandler(resource, data: data, response: response, f: f, onError: onError)
            },
            onError: { (err) -> Void in
                onError(.networkFailure(err))
            })
    }
    
    func pimpPost(_ resource: String, payload: [String: AnyObject], f: @escaping (Data) -> Void, onError: @escaping (PimpError) -> Void) {
        self.postJSON(
            URL(string: resource, relativeTo: baseURL)!,
            headers: postHeaders,
            payload: payload,
            onResponse: { (data, response) -> Void in
                self.responseHandler(resource, data: data, response: response, f: f, onError: onError)
            },
            onError: { (err) -> Void in
                onError(.networkFailure(err))
            })
    }
    
    func responseHandler(_ resource: String, data: Data, response: HTTPURLResponse, f: (Data) -> Void, onError: (PimpError) -> Void) {
        let statusCode = response.statusCode
        let isStatusOK = (statusCode >= 200) && (statusCode < 300)
        if isStatusOK {
            f(data)
        } else {
            var errorMessage: String? = nil
            if let json = Json.asJson(data) as? NSDictionary {
                errorMessage = json[JsonKeys.ERROR] as? String
            }
            onError(.responseFailure(ResponseDetails(resource: resource, code: statusCode, message: errorMessage)))
        }
    }
    
    func onRequestError(_ data: Data, error: NSError) -> Void {
        log("Error: \(data)")
    }
    
    func onMusicFolder(_ f: MusicFolder) -> Void {
        log("Tracks: \(f.tracks.count)")
    }
    
    func parseVersion(_ obj: AnyObject) -> Version? {
        if let dict = obj as? NSDictionary {
            if let version = dict[JsonKeys.VERSION] as? String {
                return Version(version: version)
          }
        }
        log("Unable to get status")
        return nil
    }
    
    func log(_ s: String) {
        Log.info(s)
    }
}
