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
    
    func postPlayback(_ cmd: String) {
        let dict = PimpEndpoint.simpleCommand(cmd)
        postDict(dict as [String : AnyObject])
    }
    
    func postValued(_ cmd: String, value: AnyObject) {
        let dict = PimpEndpoint.valuedCommand(cmd, value: value)
        postDict(dict)
    }
    
    func postDict(_ dict: [String: AnyObject]) {
        client.pimpPost(Endpoints.PLAYBACK, payload: dict, f: onSuccess, onError: onError)
    }
    
    func onSuccess(_ data: Data) {
        
    }
    
    func onError(_ error: PimpError) {
        let str = PimpErrorUtil.stringify(error)
        Log.info("Player error: \(str)")
    }
    
    static func simpleCommand(_ cmd: String) -> [String: String] {
        return [
            JsonKeys.CMD: cmd
        ]
    }
    
    static func valuedCommand(_ cmd: String, value: AnyObject) -> [String: AnyObject] {
        return [
            JsonKeys.CMD: cmd as AnyObject,
            JsonKeys.VALUE: value
        ]
    }
    
    static func parseTrack(_ obj: NSDictionary, urlMaker: (String) -> URL) -> Track? {
        if let id = obj[JsonKeys.ID] as? String,
            let title = obj[JsonKeys.TITLE] as? String,
            let artist = obj[JsonKeys.ARTIST] as? String,
            let album = obj[JsonKeys.ALBUM] as? String,
            let sizeRaw = obj[JsonKeys.SIZE] as? Int,
            let size = StorageSize.fromBytes(sizeRaw),
            let duration = obj[JsonKeys.DURATION] as? Int {
                return Track(
                    id: id,
                    title: title,
                    album: album,
                    artist: artist,
                    duration: duration.seconds,
                    path: Util.urlDecodeWithPlus(id),
                    size: size,
                    url: urlMaker(id))
        }
        return nil
    }
    
    func parseTrack(_ obj: NSDictionary) -> Track? {
        return PimpEndpoint.parseTrack(obj, urlMaker: { (id) -> URL in self.urlFor(id) })
    }
    
    func parseStatus(_ dict: NSDictionary) -> PlayerState? {
        if let trackDict = dict[JsonKeys.TRACK] as? NSDictionary,
            let stateName = dict[JsonKeys.STATE] as? String,
            let state = PlaybackState.fromName(stateName),
            let position = dict[JsonKeys.POSITION] as? Int,
            //posDuration = position.seconds,
            let mute = dict[JsonKeys.MUTE] as? Bool,
            let volume = dict[JsonKeys.VOLUME] as? Int,
            let playlist = dict[JsonKeys.PLAYLIST] as? [NSDictionary],
            let playlistIndex = dict[JsonKeys.INDEX] as? Int {
            let trackOpt = parseTrack(trackDict)
            let tracks = playlist.flatMapOpt(parseTrack)
                return PlayerState(track: trackOpt, state: state, position: position.seconds, volume: VolumeValue(volume: volume), mute: mute, playlist: tracks, playlistIndex: playlistIndex)
        }
        return nil
    }
    
}
