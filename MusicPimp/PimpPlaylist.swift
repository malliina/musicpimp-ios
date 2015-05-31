//
//  PimpPlaylist.swift
//  MusicPimp
//
//  Created by Michael Skogberg on 23/05/15.
//  Copyright (c) 2015 Skogberg Labs. All rights reserved.
//

import Foundation

class PimpPlaylist: BasePlaylist, PlaylistType {
    let client: PimpHttpClient
    let helper: PimpEndpoint
    init(client: PimpHttpClient) {
        self.client = client
        self.helper = PimpEndpoint(client: client)
    }
    func skip(index: Int) {
        helper.postValued(JsonKeys.SKIP, value: index)
    }
    func add(track: Track) {
        helper.postDict([
            JsonKeys.CMD: JsonKeys.ADD,
            JsonKeys.TRACK: track.id
        ])
    }
    func add(tracks: [Track]) {
        for track in tracks {
            add(track)
        }
    }
    func removeIndex(index: Int) {
        helper.postValued(JsonKeys.REMOVE, value: index)
    }
    private func parseStatus(obj: AnyObject) -> PlayerState? {
        if let dict = obj as? NSDictionary {
            if let trackDict = dict[JsonKeys.TRACK] as? NSDictionary {
                let trackOpt = helper.parseTrack(trackDict)
                if let stateName = dict[JsonKeys.STATE] as? String {
                    if let state = PlaybackState(rawValue: stateName) {
                        if let position = dict[JsonKeys.POSITION] as? Int {
                            if let mute = dict[JsonKeys.MUTE] as? Bool {
                                if let volume = dict[JsonKeys.VOLUME] as? Int {
                                    if let playlist = dict[JsonKeys.PLAYLIST] as? [NSDictionary] {
                                        let tracks = playlist.flatMapOpt(helper.parseTrack)
                                        if let playlistIndex = dict[JsonKeys.PLAYLIST_INDEX] as? Int {
                                            return PlayerState(track: trackOpt, state: state, position: position, volume: volume, mute: mute, playlist: tracks, playlistIndex: playlistIndex)
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
        return nil
    }
}