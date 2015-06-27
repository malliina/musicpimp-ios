//
//  PimpEndpoint.swift
//  MusicPimp
//
//  Created by Michael Skogberg on 24/05/15.
//  Copyright (c) 2015 Skogberg Labs. All rights reserved.
//

import Foundation

class PimpEndpoint {
    let endpoint: Endpoint
    let client: PimpHttpClient
    init(endpoint: Endpoint, client: PimpHttpClient) {
        self.endpoint = endpoint
        self.client = client
    }
    func postPlayback(cmd: String) {
        let dict = PimpEndpoint.simpleCommand(cmd)
        postDict(dict)
    }
    func postValued(cmd: String, value: AnyObject) {
        let dict = PimpEndpoint.valuedCommand(cmd, value: value)
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
    static func simpleCommand(cmd: String) -> [String: String] {
        return [
            JsonKeys.CMD: cmd
        ]
    }
    static func valuedCommand(cmd: String, value: AnyObject) -> [String: AnyObject] {
        return [
            JsonKeys.CMD: cmd,
            JsonKeys.VALUE: value
        ]
    }
    func parseTrack(obj: NSDictionary) -> Track? {
        if let id = obj[JsonKeys.ID] as? String,
            title = obj[JsonKeys.TITLE] as? String,
            artist = obj[JsonKeys.ARTIST] as? String,
            album = obj[JsonKeys.ALBUM] as? String,
            size = obj[JsonKeys.SIZE] as? Int,
            duration = obj[JsonKeys.DURATION] as? Int,
            durDuration = duration.seconds {
                return Track(
                    id: id,
                    title: title,
                    album: album,
                    artist: artist,
                    duration: durDuration,
                    path: Util.urlDecode(id),
                    size: Int64(size),
                    url: self.urlFor(id))
        }
        return nil
    }
    func parseStatus(dict: NSDictionary) -> PlayerState? {
        if let trackDict = dict[JsonKeys.TRACK] as? NSDictionary,
            stateName = dict[JsonKeys.STATE] as? String,
            state = PlaybackState.fromName(stateName),
            position = dict[JsonKeys.POSITION] as? Int,
            posDuration = position.seconds,
            mute = dict[JsonKeys.MUTE] as? Bool,
            volume = dict[JsonKeys.VOLUME] as? Int,
            playlist = dict[JsonKeys.PLAYLIST] as? [NSDictionary],
            playlistIndex = dict[JsonKeys.INDEX] as? Int {
            let trackOpt = parseTrack(trackDict)
            let tracks = playlist.flatMapOpt(parseTrack)
            return PlayerState(track: trackOpt, state: state, position: posDuration, volume: volume, mute: mute, playlist: tracks, playlistIndex: playlistIndex)
        }
        return nil
    }
    // for cloud, keys s, u, p
    func urlFor(trackID: String) -> NSURL {
        return NSURL(string: "\(endpoint.httpBaseUrl)/tracks/\(trackID)?\(endpoint.authQueryString)")!
    }
}