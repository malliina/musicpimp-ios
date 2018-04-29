//
//  PimpHttpClient.swift
//  MusicPimp
//
//  Created by Michael Skogberg on 21/03/15.
//  Copyright (c) 2015 Skogberg Labs. All rights reserved.
//

import Foundation
import RxSwift

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
    private let log = LoggerFactory.shared.pimp(PimpHttpClient.self)
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
    
    func pingAuth() -> Observable<Version> {
        return pimpGetParsed(Endpoints.PING_AUTH, parse: self.parseVersion)
    }
    
    func pimpGetParsed<T>(_ resource: String, parse: @escaping (HttpResponse) throws -> T) -> Observable<T> {
        let req = buildGet(url: urlTo(resource), headers: defaultHeaders)
        return executeParsed(req, parse: parse)
    }
    
    func pimpGetParsedJson<T>(_ resource: String, parse: @escaping (NSDictionary) throws -> T) -> Observable<T> {
        let req = buildGet(url: urlTo(resource), headers: defaultHeaders)
        return executeParsedJson(req, parse: parse)
    }
    
    func pimpPostParsed<T>(_ resource: String, payload: [String: AnyObject], parse: @escaping (NSDictionary) throws -> T) -> Observable<T> {
        return pimpPost(resource, payload: payload).flatMap { response in
            self.recovered { () -> T in
                try self.asJson(response: response, parse: parse)
            }
        }
    }
    
    func pimpPost(_ resource: String, payload: [String: AnyObject]) -> Observable<HttpResponse> {
        let req = buildRequest(url: urlTo(resource), httpMethod: HttpClient.POST, headers: postHeaders, body: try? JSONSerialization.data(withJSONObject: payload, options: []))
        return executeChecked(req)
    }
 
    func urlTo(_ resource: String) -> URL {
        return URL(string: resource, relativeTo: baseURL)!
    }
    
    func onRequestError(_ data: Data, error: NSError) -> Void {
        log.error("Error: \(data)")
    }
    
    func onMusicFolder(_ f: MusicFolder) -> Void {
        log.info("Tracks: \(f.tracks.count)")
    }
    
    func parseVersion(_ response: HttpResponse) throws -> Version {
        guard let json = response.json else { throw JsonError.notJson(response.data) }
        guard let version = json[JsonKeys.VERSION] as? String else { throw JsonError.missing(JsonKeys.VERSION) }
        return Version(version: version)
    }
}
