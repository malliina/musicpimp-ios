//
//  PimpLibrary.swift
//  MusicPimp
//
//  Created by Michael Skogberg on 23/05/15.
//  Copyright (c) 2015 Skogberg Labs. All rights reserved.
//

import Foundation

open class PimpLibrary: BaseLibrary {
    let endpoint: Endpoint
    let client: PimpHttpClient
    let helper: PimpUtils
    
    init(endpoint: Endpoint, client: PimpHttpClient) {
        self.endpoint = endpoint
        self.client = client
        self.helper = PimpUtils(endpoint: endpoint)
    }

    override func pingAuth(_ onError: @escaping (PimpError) -> Void, f: @escaping (Version) -> Void) {
        client.pingAuth(onError, f: f)
    }
    
    override func rootFolder(_ onError: @escaping (PimpError) -> Void, f: @escaping (MusicFolder) -> Void) {
        client.pimpGetParsed(Endpoints.FOLDERS, parse: parseMusicFolder, f: f, onError: onError)
    }
    
    override func folder(_ id: String, onError: @escaping (PimpError) -> Void, f: @escaping (MusicFolder) -> Void) {
        client.pimpGetParsed("\(Endpoints.FOLDERS)/\(id)", parse: parseMusicFolder, f: f, onError: onError)
    }
    
    override func tracks(_ id: String, onError: @escaping (PimpError) -> Void, f: @escaping ([Track]) -> Void) {
        tracksInner(id,  others: [], acc: [], f: f, onError: onError)
    }
    
    override func playlists(_ onError: @escaping (PimpError) -> Void, f: @escaping ([SavedPlaylist]) -> Void) {
        client.pimpGetParsed("\(Endpoints.PLAYLISTS)", parse: parsePlaylists, f: f, onError: onError)
    }
    
    override func playlist(_ id: PlaylistID, onError: @escaping (PimpError) -> Void, f: @escaping (SavedPlaylist) -> Void) {
        client.pimpGetParsed("\(Endpoints.PLAYLISTS)\(id.id)", parse: parseGetPlaylistResponse, f: f, onError: onError)
    }
    
    override func popular(_ from: Int, until: Int, onError: @escaping (PimpError) -> Void, f: @escaping ([PopularEntry]) -> Void) {
        client.pimpGetParsed("\(Endpoints.Popular)?from=\(from)&until=\(until)", parse: parsePopulars, f: f, onError: onError)
    }
    
    override func recent(_ from: Int, until: Int, onError: @escaping (PimpError) -> Void, f: @escaping ([RecentEntry]) -> Void) {
        client.pimpGetParsed("\(Endpoints.Recent)?from=\(from)&until=\(until)", parse: parseRecents, f: f, onError: onError)
    }
    
    override func savePlaylist(_ sp: SavedPlaylist, onError: @escaping (PimpError) -> Void, onSuccess: @escaping (PlaylistID) -> Void) {
        let json = [
            JsonKeys.PLAYLIST: SavedPlaylist.toJson(sp) as AnyObject
        ]
        client.pimpPost("\(Endpoints.PLAYLISTS)", payload: json, f: { (data) -> Void in
            if let jsonObj = Json.asJson(data), let id = self.parsePlaylistID(jsonObj) {
                onSuccess(id)
            } else {
                onError(PimpError.simpleError(ErrorMessage(message: "Response parsing failed, got \(data)")))
            }
            }, onError: onError)
    }
    
    override func deletePlaylist(_ id: PlaylistID, onError: @escaping (PimpError) -> Void, onSuccess: @escaping () -> Void) {
        client.pimpPost("\(Endpoints.PLAYLIST_DELETE)/\(id.id)", payload: [:], f: { (data) -> Void in
            onSuccess(())
            }, onError: onError)
    }
    
    override func search(_ term: String, onError: @escaping (PimpError) -> Void, ts: @escaping ([Track]) -> Void) {
        if let encodedTerm = term.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed) {
            client.pimpGetParsed("\(Endpoints.SEARCH)?term=\(encodedTerm)", parse: parseTracks, f: ts, onError: onError)
        } else {
            onError(PimpError.simple("Invalid search term: \(term)"))
        }
    }
    
    override func alarms(_ onError: @escaping (PimpError) -> Void, f: @escaping ([Alarm]) -> Void) {
        client.pimpGetParsed(Endpoints.ALARMS, parse: parseAlarms, f: f, onError: onError)
    }
    
    override func saveAlarm(_ alarm: Alarm, onError: @escaping (PimpError) -> Void, onSuccess: @escaping () -> Void) {
        let payload: [String: AnyObject] = [
            JsonKeys.CMD: JsonKeys.Save as AnyObject,
            JsonKeys.Ap: Alarm.toJson(alarm) as AnyObject,
            JsonKeys.Enabled: alarm.enabled as AnyObject
        ]
        client.pimpPost(Endpoints.ALARMS, payload: payload, f: { (data) -> Void in
            onSuccess(())
            }, onError: onError)
    }
    
    override func deleteAlarm(_ id: AlarmID, onError: @escaping (PimpError) -> Void, onSuccess: @escaping () -> Void) {
        let payload = [
            JsonKeys.CMD : JsonKeys.DELETE,
            JsonKeys.ID : id.id
        ]
        alarmsPost(payload as [String : AnyObject], onError: onError, onSuccess: onSuccess)
    }
    
    override func stopAlarm(_ onError: @escaping (PimpError) -> Void, onSuccess: @escaping () -> Void) {
        let payload = [
            JsonKeys.CMD: JsonKeys.STOP
        ]
        alarmsPost(payload as [String : AnyObject], onError: onError, onSuccess: onSuccess)
    }
    
    override func registerNotifications(_ token: PushToken, tag: String, onError: @escaping (PimpError) -> Void, onSuccess: @escaping () -> Void) {
        let payload = [
            JsonKeys.CMD: JsonKeys.ApnsAdd,
            JsonKeys.Id: token.token,
            JsonKeys.ApnsTag: tag
        ]
        alarmsPost(payload as [String : AnyObject], onError: onError, onSuccess: onSuccess)
    }
    
    override func unregisterNotifications(_ tag: String, onError: @escaping (PimpError) -> Void, onSuccess: @escaping () -> Void) {
        let payload = [
            JsonKeys.CMD: JsonKeys.ApnsRemove,
            JsonKeys.Id: tag
        ]
        alarmsPost(payload as [String : AnyObject], onError: onError, onSuccess: onSuccess)
    }
    
    fileprivate func alarmsPost(_ payload: [String: AnyObject], onError: @escaping (PimpError) -> Void, onSuccess: @escaping () -> Void) {
        client.pimpPost(Endpoints.ALARMS, payload: payload, f: { (data) -> Void in
            onSuccess(())
            }, onError: onError)
    }
    
    fileprivate func tracksInner(_ id: String, others: [String], acc: [Track], f: @escaping ([Track]) -> Void, onError: @escaping (PimpError) -> Void){
        folder(id, onError: onError) { result in
            let subIDs = result.folders.map { $0.id }
            let remaining = others + subIDs
            let newAcc = acc + result.tracks
            if let head = remaining.first {
                let tail = remaining.tail()
                self.tracksInner(head, others: tail, acc: newAcc, f: f, onError: onError)
            } else {
                f(newAcc)
            }
        }
    }
    
    func parseFolder(_ obj: NSDictionary) -> Folder? {
        if let id = obj[JsonKeys.ID] as? String,
            let title = obj[JsonKeys.TITLE] as? String,
            let path = obj[JsonKeys.PATH] as? String {
                return Folder(
                    id: id,
                    title: title,
                    path: path)
        }
        return nil
    }
    
    func parseTrack(_ dict: NSDictionary) -> Track? {
        return PimpEndpoint.parseTrack(dict, urlMaker: { (id) -> URL in self.helper.urlFor(id) })
    }

    func parseMusicFolder(_ obj: AnyObject) -> MusicFolder? {
        if let dict = obj as? NSDictionary,
            let folderJSON = dict[JsonKeys.FOLDER] as? NSDictionary,
            let foldersJSON = dict[JsonKeys.FOLDERS] as? NSArray,
            let tracksJSON = dict[JsonKeys.TRACKS] as? NSArray,
            let root = parseFolder(folderJSON) {
                if let foldObjects = foldersJSON as? [NSDictionary] {
                    let folders: [Folder] = foldObjects.flatMapOpt(parseFolder)
                    if let trackObjects = tracksJSON as? [NSDictionary] {
                        let tracks: [Track] = trackObjects.flatMapOpt(parseTrack)
                        return MusicFolder(folder: root, folders: folders, tracks: tracks)
                    }
                }
        }
        Log.info("Unable to parse \(obj) as music folder")
        return nil
    }
    
    func parsePlaylists(_ obj: AnyObject) -> [SavedPlaylist] {
        if let obj = obj as? NSDictionary,
            let playlistsArr = obj[JsonKeys.PLAYLISTS] as? [NSDictionary] {
            return playlistsArr.flatMapOpt(parsePlaylist)
        } else {
            return []
        }
    }
    
    func parseGetPlaylistResponse(_ obj: AnyObject) -> SavedPlaylist? {
        if let obj = obj as? NSDictionary, let playlistObj = obj[JsonKeys.PLAYLIST] as? NSDictionary {
            return parsePlaylist(playlistObj)
        } else {
            return nil
        }
    }
    
    func parsePopulars(_ obj: AnyObject) -> [PopularEntry]? {
        return parseArray(obj, key: JsonKeys.Populars, single: parsePopular)
    }
    
    func parsePopular(_ dict: NSDictionary) -> PopularEntry? {
        if let trackDict = dict[JsonKeys.TRACK] as? NSDictionary,
            let count = dict[JsonKeys.PlaybackCount] as? Int,
            let track = parseTrack(trackDict) {
            return PopularEntry(track: track, playbackCount: count)
        } else {
            return nil
        }
    }
    
    func parseRecents(_ obj: AnyObject) -> [RecentEntry]? {
        return parseArray(obj, key: JsonKeys.Recents, single: parseRecent)
    }
    
    func parseRecent(_ dict: NSDictionary) -> RecentEntry? {
        if let trackDict = dict[JsonKeys.TRACK] as? NSDictionary,
            let when = dict[JsonKeys.WHEN] as? UInt,
            let track = parseTrack(trackDict) {
            let whenSeconds: Double = Double(when / 1000)
            return RecentEntry(track: track, when: Date(timeIntervalSince1970: whenSeconds))
        } else {
            Log.error("Unable to parse track from dictionary \(dict)")
            return nil
        }
    }
    
    func parseArray<T>(_ obj: AnyObject, key: String, single: (NSDictionary) -> T?) -> [T]? {
        if let obj = obj as? NSDictionary, let entriesArr = obj[key] as? [NSDictionary] {
            return entriesArr.flatMapOpt(single)
        } else {
            return nil
        }
    }
    
    func parsePlaylist(_ obj: AnyObject) -> SavedPlaylist? {
        if let obj = obj as? NSDictionary,
            let id = obj[JsonKeys.ID] as? Int,
            let name = obj[JsonKeys.NAME] as? String,
            let tracksArr = obj[JsonKeys.TRACKS] as? [NSDictionary] {
            let tracks = tracksArr.flatMapOpt(parseTrack)
                return SavedPlaylist(id: PlaylistID(id: id), name: name, tracks: tracks)
        } else {
            return nil
        }
    }
    
    func parsePlaylistID(_ obj: AnyObject) -> PlaylistID? {
        if let obj = obj as? NSDictionary, let id = obj[JsonKeys.ID] as? Int {
            return PlaylistID(id: id)
        } else {
            return nil
        }
    }
    
    func parseTracks(_ obj: AnyObject) -> [Track]? {
        if let arr = obj as? [NSDictionary] {
            let tracks = arr.flatMapOpt(parseTrack)
            return tracks
        }
        Log.info("Unable to parse tracks from \(obj)")
        return nil
    }
    
    func parseAlarms(_ obj: AnyObject) -> [Alarm] {
        if let arr = obj as? [NSDictionary] {
            return arr.flatMapOpt(parseAlarm)
        } else {
            return []
        }
    }
    
    func parseAlarm(_ dict: NSDictionary) -> Alarm? {
        if let id = dict[JsonKeys.ID] as? String,
            let job = dict[JsonKeys.JOB] as? NSDictionary,
            let trackDict = job[JsonKeys.TRACK] as? NSDictionary,
            let track = parseTrack(trackDict),
            let when = dict[JsonKeys.WHEN] as? NSDictionary,
            let hour = when[JsonKeys.Hour] as? Int,
            let minute = when[JsonKeys.Minute] as? Int,
            let dayNames = when[JsonKeys.Days] as? [String],
            let enabled = dict[JsonKeys.Enabled] as? Bool {
            let days = dayNames.flatMapOpt(Day.fromName)
                if days.count == dayNames.count {
                    let daysSet = Set(days)
                    return Alarm(id: AlarmID(id: id), track: track, when: AlarmTime(hour: hour, minute: minute, days: daysSet), enabled: enabled)
                }
                
        }
        Log.info("Unable to parse alarm. \(dict)")
        return nil
    }
}
