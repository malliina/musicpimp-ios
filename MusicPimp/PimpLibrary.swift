//
//  PimpLibrary.swift
//  MusicPimp
//
//  Created by Michael Skogberg on 23/05/15.
//  Copyright (c) 2015 Skogberg Labs. All rights reserved.
//

import Foundation
import RxSwift

open class PimpLibrary: BaseLibrary {
    let endpoint: Endpoint
    let client: PimpHttpClient
    let helper: PimpUtils
    
    init(endpoint: Endpoint, client: PimpHttpClient) {
        self.endpoint = endpoint
        self.client = client
        self.helper = PimpUtils(endpoint: endpoint)
    }

    override func pingAuth() -> Observable<Version> {
        return client.pingAuth()
    }
    
    override func rootFolder() -> Observable<MusicFolder> {
        return client.pimpGetParsed(Endpoints.FOLDERS, parse: parseMusicFolder)
    }
    
    override func folder(_ id: String) -> Observable<MusicFolder> {
        return client.pimpGetParsed("\(Endpoints.FOLDERS)/\(id)", parse: parseMusicFolder)
    }
    
    override func tracks(_ id: String) -> Observable<[Track]> {
        return tracksInner(id,  others: [], acc: [])
    }
    
    override func playlists() -> Observable<[SavedPlaylist]> {
        return client.pimpGetParsed("\(Endpoints.PLAYLISTS)", parse: parsePlaylists)
    }
    
    override func playlist(_ id: PlaylistID) -> Observable<SavedPlaylist> {
        return client.pimpGetParsed("\(Endpoints.PLAYLISTS)\(id.id)", parse: parseGetPlaylistResponse)
    }
    
    override func popular(_ from: Int, until: Int) -> Observable<[PopularEntry]> {
        return client.pimpGetParsed("\(Endpoints.Popular)?from=\(from)&until=\(until)", parse: parsePopulars)
    }
    
    override func recent(_ from: Int, until: Int) -> Observable<[RecentEntry]> {
        return client.pimpGetParsed("\(Endpoints.Recent)?from=\(from)&until=\(until)", parse: parseRecents)
    }
    
    override func savePlaylist(_ sp: SavedPlaylist, onError: @escaping (PimpError) -> Void, onSuccess: @escaping (PlaylistID) -> Void) {
        let json = [
            JsonKeys.PLAYLIST: SavedPlaylist.toJson(sp) as AnyObject
        ]
        client.pimpPost("\(Endpoints.PLAYLISTS)", payload: json, f: { (data) -> Void in
            if let json = Json.asJson(data) {
                do {
                    let id = try self.parsePlaylistID(json)
                    onSuccess(id)
                } catch let error as JsonError {
                    onError(.parseError(error))
                } catch _ {
                    onError(.simple("Unknown parse error."))
                }
            } else {
                onError(.parseError(JsonError.notJson(data)))
            }
            }, onError: onError)
    }
    
    override func deletePlaylist(_ id: PlaylistID, onError: @escaping (PimpError) -> Void, onSuccess: @escaping () -> Void) {
        client.pimpPost("\(Endpoints.PLAYLIST_DELETE)/\(id.id)", payload: [:], f: { (data) -> Void in
            onSuccess()
            }, onError: onError)
    }
    
    override func search(_ term: String) -> Observable<[Track]> {
        if let encodedTerm = term.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed) {
            return client.pimpGetParsed("\(Endpoints.SEARCH)?term=\(encodedTerm)", parse: parseTracks)
        } else {
            return Observable.error(PimpError.simple("Invalid search term: \(term)"))
        }
    }
    
    override func alarms() -> Observable<[Alarm]> {
        return client.pimpGetParsed(Endpoints.ALARMS, parse: parseAlarms)
    }
    
    override func saveAlarm(_ alarm: Alarm, onError: @escaping (PimpError) -> Void, onSuccess: @escaping () -> Void) {
        let payload: [String: AnyObject] = [
            JsonKeys.CMD: JsonKeys.Save as AnyObject,
            JsonKeys.Ap: Alarm.toJson(alarm) as AnyObject,
            JsonKeys.Enabled: alarm.enabled as AnyObject
        ]
        client.pimpPost(Endpoints.ALARMS, payload: payload, f: { (data) -> Void in
            onSuccess()
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
            onSuccess()
            }, onError: onError)
    }
    
//    fileprivate func tracksInner(_ id: String, others: [String], acc: [Track]){
//        return folder(id, onError: onError) { result in
//            let subIDs = result.folders.map { $0.id }
//            let remaining = others + subIDs
//            let newAcc = acc + result.tracks
//            if let head = remaining.first {
//                let tail = remaining.tail()
//                self.tracksInner(head, others: tail, acc: newAcc, f: f, onError: onError)
//            } else {
//                f(newAcc)
//            }
//        }
//    }
    
    func parseFolder(_ obj: NSDictionary) throws -> Folder {
        let id = try readString(obj, JsonKeys.ID)
        let title = try readString(obj, JsonKeys.TITLE)
        let path = try readString(obj, JsonKeys.PATH)
        return Folder(id: id, title: title, path: path)
    }
    
    func parseTrack(_ dict: NSDictionary) throws -> Track {
        return try PimpEndpoint.parseTrack(dict, urlMaker: { (id) -> URL in self.helper.urlFor(id) })
    }

    func parseMusicFolder(_ obj: AnyObject) throws -> MusicFolder {
        let dict = try readObject(obj)
        let folderJSON: NSDictionary = try readOrFail(dict, JsonKeys.FOLDER)
        let foldersJSON: [NSDictionary] = try readOrFail(dict, JsonKeys.FOLDERS)
        let tracksJSON: [NSDictionary] = try readOrFail(dict, JsonKeys.TRACKS)
        let root = try parseFolder(folderJSON)
        let folders = try foldersJSON.map(parseFolder)
        let tracks = try tracksJSON.map(parseTrack)
        return MusicFolder(folder: root, folders: folders, tracks: tracks)
    }
    
    func parsePlaylists(_ obj: AnyObject) throws -> [SavedPlaylist] {
        let dict = try readObject(obj)
        let playlists: [NSDictionary] = try readOrFail(dict, JsonKeys.PLAYLISTS)
        return try playlists.map(parsePlaylist)
    }
    
    func parseGetPlaylistResponse(_ obj: AnyObject) throws -> SavedPlaylist {
        let dict = try readObject(obj)
        let playlist: NSDictionary = try readOrFail(dict, JsonKeys.PLAYLIST)
        return try parsePlaylist(playlist)
    }
    
    func parsePopulars(_ obj: AnyObject) throws -> [PopularEntry] {
        return try parseArray(obj, key: JsonKeys.Populars, single: parsePopular)
    }
    
    func parsePopular(_ dict: NSDictionary) throws -> PopularEntry {
        let trackDict: NSDictionary = try readOrFail(dict, JsonKeys.TRACK)
        let track = try parseTrack(trackDict)
        let count = try readInt(dict, JsonKeys.PlaybackCount)
        return PopularEntry(track: track, playbackCount: count)
    }
    
    func parseRecents(_ obj: AnyObject) throws -> [RecentEntry] {
        return try parseArray(obj, key: JsonKeys.Recents, single: parseRecent)
    }
    
    func parseRecent(_ dict: NSDictionary) throws -> RecentEntry {
        let trackDict: NSDictionary = try readOrFail(dict, JsonKeys.TRACK)
        let track = try parseTrack(trackDict)
        let when = try readInt(dict, RecentEntry.When)
        let whenSeconds: Double = Double(when / 1000)
        return RecentEntry(track: track, when: Date(timeIntervalSince1970: whenSeconds))
    }
    
    func parseArray<T>(_ obj: AnyObject, key: String, single: (NSDictionary) throws -> T) throws -> [T] {
        let obj = try readObject(obj)
        let entries: [NSDictionary] = try readOrFail(obj, key)
        return try entries.map(single)
    }
    
    func parsePlaylist(_ obj: AnyObject) throws -> SavedPlaylist {
        let obj = try readObject(obj)
        let id = try readInt(obj, JsonKeys.ID)
        let name = try readString(obj, JsonKeys.NAME)
        let tracksArr: [NSDictionary] = try readOrFail(obj, JsonKeys.TRACKS)
        let tracks = try tracksArr.map(parseTrack)
        return SavedPlaylist(id: PlaylistID(id: id), name: name, tracks: tracks)
    }
    
    func parsePlaylistID(_ obj: AnyObject) throws -> PlaylistID {
        let obj = try readObject(obj)
        let asInt = try readInt(obj, JsonKeys.ID)
        return PlaylistID(id: asInt)
    }
    
    func parseTracks(_ obj: AnyObject) throws -> [Track] {
        let arr = try readArray(obj)
        return try arr.map(parseTrack)
    }
    
    func parseAlarms(_ obj: AnyObject) throws -> [Alarm] {
        let arr = try readArray(obj)
        return try arr.map(parseAlarm)
    }
    
    func parseAlarm(_ dict: NSDictionary) throws -> Alarm {
        let id = try readString(dict, JsonKeys.ID)
        let job: NSDictionary = try readOrFail(dict, JsonKeys.JOB)
        let trackDict: NSDictionary = try readOrFail(job, JsonKeys.TRACK)
        let track = try parseTrack(trackDict)
        let whenDict: NSDictionary = try readOrFail(dict, JsonKeys.WHEN)
        let hour = try readInt(whenDict, JsonKeys.Hour)
        let minute = try readInt(whenDict, JsonKeys.Minute)
        let daysNames: [String] = try readOrFail(whenDict, JsonKeys.Days)
        let enabled: Bool = try readOrFail(dict, JsonKeys.Enabled)
        let days = daysNames.flatMapOpt(Day.fromName)
        if days.count != daysNames.count {
            throw JsonError.invalid(JsonKeys.Days, daysNames)
        }
        return Alarm(id: AlarmID(id: id), track: track, when: AlarmTime(hour: hour, minute: minute, days: Set(days)), enabled: enabled)
    }
    
    func readArray(_ obj: AnyObject) throws -> [NSDictionary] {
        if let arr = obj as? [NSDictionary] {
            return arr
        }
        throw JsonError.invalid("object", obj)
    }
    
    func readObject(_ obj: AnyObject) throws -> NSDictionary {
        if let obj = obj as? NSDictionary {
            return obj
        }
        throw JsonError.invalid("object", obj)

    }
    
    func readString(_ obj: NSDictionary, _ key: String) throws -> String {
        return try Json.readOrFail(obj, key)
    }
    
    func readInt(_ obj: NSDictionary, _ key: String) throws -> Int {
        return try Json.readOrFail(obj, key)
    }
    
    func readOrFail<T>(_ obj: NSDictionary, _ key: String) throws -> T {
        return try Json.readOrFail(obj, key)
    }
}
