//
//  PimpEndpoint.swift
//  MusicPimp
//
//  Created by Michael Skogberg on 24/05/15.
//  Copyright (c) 2015 Skogberg Labs. All rights reserved.
//

import Foundation

class PimpEndpoint: PimpUtils {
    let client: PimpHttpClient
    
    init(endpoint: Endpoint, client: PimpHttpClient) {
        self.client = client
        super.init(endpoint: endpoint)
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
    
    static func parseTrack(obj: NSDictionary, urlMaker: String -> NSURL) -> Track? {
        if let id = obj[JsonKeys.ID] as? String,
            title = obj[JsonKeys.TITLE] as? String,
            artist = obj[JsonKeys.ARTIST] as? String,
            album = obj[JsonKeys.ALBUM] as? String,
            sizeRaw = obj[JsonKeys.SIZE] as? Int,
            size = StorageSize.fromBytes(sizeRaw),
            duration = obj[JsonKeys.DURATION] as? Int {
                return Track(
                    id: id,
                    title: title,
                    album: album,
                    artist: artist,
                    duration: duration.seconds,
                    path: Util.urlDecode(id),
                    size: size,
                    url: urlMaker(id))
        }
        return nil
    }
    
    func parseTrack(obj: NSDictionary) -> Track? {
        return PimpEndpoint.parseTrack(obj, urlMaker: { (id) -> NSURL in self.urlFor(id) })
    }
    
    func parseStatus(dict: NSDictionary) -> PlayerState? {
        if let trackDict = dict[JsonKeys.TRACK] as? NSDictionary,
            stateName = dict[JsonKeys.STATE] as? String,
            state = PlaybackState.fromName(stateName),
            position = dict[JsonKeys.POSITION] as? Int,
            //posDuration = position.seconds,
            mute = dict[JsonKeys.MUTE] as? Bool,
            volume = dict[JsonKeys.VOLUME] as? Int,
            playlist = dict[JsonKeys.PLAYLIST] as? [NSDictionary],
            playlistIndex = dict[JsonKeys.INDEX] as? Int {
            let trackOpt = parseTrack(trackDict)
            let tracks = playlist.flatMapOpt(parseTrack)
                return PlayerState(track: trackOpt, state: state, position: position.seconds, volume: VolumeValue(volume: volume), mute: mute, playlist: tracks, playlistIndex: playlistIndex)
        }
        return nil
    }
    
}