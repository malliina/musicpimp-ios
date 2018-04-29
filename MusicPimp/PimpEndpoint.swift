//
//  PimpEndpoint.swift
//  MusicPimp
//
//  Created by Michael Skogberg on 24/05/15.
//  Copyright (c) 2015 Skogberg Labs. All rights reserved.
//

import Foundation
import RxSwift

class PimpEndpoint: PimpUtils {
    let log = LoggerFactory.shared.pimp(PimpEndpoint.self)
    let client: PimpHttpClient
    
    let bag = DisposeBag()
    
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
        client.pimpPost(Endpoints.PLAYBACK, payload: dict).subscribe { (event) in
            switch event {
            case .next(let response): self.onSuccess(response.data)
            case .error(let err): self.onError(err)
            case .completed: ()
            }
        }.disposed(by: bag)
    }
    
    func onSuccess(_ data: Data) {
        
    }
    
    func onError(_ error: Error) {
        log.info("Player error: \(error.message)")
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
    
    static func parseTrack(_ obj: NSDictionary, urlMaker: (String) -> URL) throws -> Track {
        let id = try Json.readString(obj, JsonKeys.ID)
        let sizeRaw = try Json.readInt(obj, JsonKeys.SIZE)
        guard let size = StorageSize.fromBytes(sizeRaw) else { throw JsonError.invalid(JsonKeys.SIZE, sizeRaw) }
        let duration = try Json.readInt(obj, JsonKeys.DURATION)
        return Track(
                    id: id,
                    title: try Json.readString(obj, JsonKeys.TITLE),
                    album: try Json.readString(obj, JsonKeys.ALBUM),
                    artist: try Json.readString(obj, JsonKeys.ARTIST),
                    duration: duration.seconds,
                    path: try Json.readString(obj, JsonKeys.PATH),
                    size: size,
                    url: urlMaker(id)
        )
    }

    func parseTrack(_ obj: NSDictionary) throws -> Track {
        return try PimpEndpoint.parseTrack(obj, urlMaker: { (id) -> URL in self.urlFor(id) } )
    }
    
    func parseStatus(_ dict: NSDictionary) throws -> PlayerState {
        let trackDict: NSDictionary = try Json.readOrFail(dict, JsonKeys.TRACK)
        let track = try parseTrack(trackDict)
        let stateName = try Json.readString(dict, JsonKeys.STATE)
        guard let state = PlaybackState.fromName(stateName) else { throw JsonError.invalid(JsonKeys.STATE, stateName) }
        let position = try Json.readInt(dict, JsonKeys.POSITION)
        let mute: Bool = try Json.readOrFail(dict, JsonKeys.MUTE)
        let volume = try Json.readInt(dict, JsonKeys.VOLUME)
        let playlist: [NSDictionary] = try Json.readOrFail(dict, JsonKeys.PLAYLIST)
        let tracks = try playlist.compactMap(parseTrack)
        let playlistIndex = try Json.readInt(dict, JsonKeys.INDEX)
        return PlayerState(track: track, state: state, position: position.seconds, volume: VolumeValue(volume: volume), mute: mute, playlist: tracks, playlistIndex: playlistIndex)
    }
}
