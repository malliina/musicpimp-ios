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
        return client.pimpGetParsedJson(Endpoints.FOLDERS, parse: parseMusicFolder)
    }
    
    override func folder(_ id: String) -> Observable<MusicFolder> {
        return client.pimpGetParsedJson("\(Endpoints.FOLDERS)/\(id)", parse: parseMusicFolder)
    }
    
    override func tracks(_ id: String) -> Observable<[Track]> {
        return tracksInner(id,  others: [], acc: [])
    }
    
    override func playlists() -> Observable<[SavedPlaylist]> {
        return client.pimpGetParsedJson("\(Endpoints.PLAYLISTS)", parse: parsePlaylists)
    }
    
    override func playlist(_ id: PlaylistID) -> Observable<SavedPlaylist> {
        return client.pimpGetParsedJson("\(Endpoints.PLAYLISTS)\(id.id)", parse: parseGetPlaylistResponse)
    }
    
    override func popular(_ from: Int, until: Int) -> Observable<[PopularEntry]> {
        return client.pimpGetParsedJson("\(Endpoints.Popular)?from=\(from)&until=\(until)", parse: parsePopulars)
    }
    
    override func recent(_ from: Int, until: Int) -> Observable<[RecentEntry]> {
        return client.pimpGetParsedJson("\(Endpoints.Recent)?from=\(from)&until=\(until)", parse: parseRecents)
    }
    
    override func savePlaylist(_ sp: SavedPlaylist) -> Observable<PlaylistID> {
        let json = [
            JsonKeys.PLAYLIST: SavedPlaylist.toJson(sp) as AnyObject
        ]
        return client.pimpPostParsed(Endpoints.PLAYLISTS, payload: json, parse: self.parsePlaylistID)
    }
    
    override func deletePlaylist(_ id: PlaylistID) -> Observable<HttpResponse> {
        return client.pimpPost("\(Endpoints.PLAYLIST_DELETE)/\(id.id)", payload: [:])
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
    
    override func saveAlarm(_ alarm: Alarm) -> Observable<HttpResponse> {
        let payload: [String: AnyObject] = [
            JsonKeys.CMD: JsonKeys.Save as AnyObject,
            JsonKeys.Ap: Alarm.toJson(alarm) as AnyObject,
            JsonKeys.Enabled: alarm.enabled as AnyObject
        ]
        return client.pimpPost(Endpoints.ALARMS, payload: payload)
    }
    
    override func deleteAlarm(_ id: AlarmID) -> Observable<HttpResponse> {
        let payload = [
            JsonKeys.CMD : JsonKeys.DELETE,
            JsonKeys.ID : id.id
        ]
        return alarmsPost(payload as [String : AnyObject])
    }
    
    override func stopAlarm() -> Observable<HttpResponse> {
        let payload = [
            JsonKeys.CMD: JsonKeys.STOP
        ]
        return alarmsPost(payload as [String : AnyObject])
    }
    
    override func registerNotifications(_ token: PushToken, tag: String) -> Observable<HttpResponse> {
        let payload = [
            JsonKeys.CMD: JsonKeys.ApnsAdd,
            JsonKeys.Id: token.token,
            JsonKeys.ApnsTag: tag
        ]
        return alarmsPost(payload as [String : AnyObject])
    }
    
    override func unregisterNotifications(_ tag: String) -> Observable<HttpResponse> {
        let payload = [
            JsonKeys.CMD: JsonKeys.ApnsRemove,
            JsonKeys.Id: tag
        ]
        return alarmsPost(payload as [String : AnyObject])
    }
    
    fileprivate func alarmsPost(_ payload: [String: AnyObject]) -> Observable<HttpResponse> {
        return client.pimpPost(Endpoints.ALARMS, payload: payload)
    }
    
    func parseFolder(_ json: NSDictionary) throws -> Folder {
        let id = try readString(json, JsonKeys.ID)
        let title = try readString(json, JsonKeys.TITLE)
        let path = try readString(json, JsonKeys.PATH)
        return Folder(id: id, title: title, path: path)
    }
    
    func parseTrack(_ json: NSDictionary) throws -> Track {
        return try PimpEndpoint.parseTrack(json, urlMaker: { (id) -> URL in self.helper.urlFor(id) })
    }

    func parseMusicFolder(_ json: NSDictionary) throws -> MusicFolder {
        let folderJSON: NSDictionary = try readOrFail(json, JsonKeys.FOLDER)
        let foldersJSON: [NSDictionary] = try readOrFail(json, JsonKeys.FOLDERS)
        let tracksJSON: [NSDictionary] = try readOrFail(json, JsonKeys.TRACKS)
        let root = try parseFolder(folderJSON)
        let folders = try foldersJSON.map(parseFolder)
        let tracks = try tracksJSON.map(parseTrack)
        return MusicFolder(folder: root, folders: folders, tracks: tracks)
    }
    
    func parsePlaylists(_ json: NSDictionary) throws -> [SavedPlaylist] {
        let playlists: [NSDictionary] = try readOrFail(json, JsonKeys.PLAYLISTS)
        return try playlists.map(parsePlaylist)
    }
    
    func parseGetPlaylistResponse(_ json: NSDictionary) throws -> SavedPlaylist {
        let playlist: NSDictionary = try readOrFail(json, JsonKeys.PLAYLIST)
        return try parsePlaylist(playlist)
    }
    
    func parsePopulars(_ obj: NSDictionary) throws -> [PopularEntry] {
        return try parseArray(obj, key: JsonKeys.Populars, single: parsePopular)
    }
    
    func parsePopular(_ dict: NSDictionary) throws -> PopularEntry {
        let trackDict: NSDictionary = try readOrFail(dict, JsonKeys.TRACK)
        let track = try parseTrack(trackDict)
        let count = try readInt(dict, JsonKeys.PlaybackCount)
        return PopularEntry(track: track, playbackCount: count)
    }
    
    func parseRecents(_ obj: NSDictionary) throws -> [RecentEntry] {
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
    
    func parsePlaylist(_ obj: NSDictionary) throws -> SavedPlaylist {
        let tracksArr: [NSDictionary] = try readOrFail(obj, JsonKeys.TRACKS)
        let tracks = try tracksArr.map(parseTrack)
        return SavedPlaylist(
            id: PlaylistID(id: try readInt(obj, JsonKeys.ID)),
            name: try readString(obj, JsonKeys.NAME),
            trackCount: try readInt(obj, "trackCount"),
            tracks: tracks
        )
    }
    
    func parsePlaylistID(_ obj: NSDictionary) throws -> PlaylistID {
        let asInt = try readInt(obj, JsonKeys.ID)
        return PlaylistID(id: asInt)
    }
    
    func parseTracks(_ response: HttpResponse) throws -> [Track] {
//        let obj = try readObject(obj)
        let arr = try readArray(response)
        return try arr.map(parseTrack)
    }
    
    func parseAlarms(_ obj: HttpResponse) throws -> [Alarm] {
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
    
    func readArray(_ response: HttpResponse) throws -> [NSDictionary] {
        guard let obj = response.jsonData else { throw JsonError.notJson(response.data) }
        guard let arr = obj as? [NSDictionary] else { throw JsonError.invalid("object", obj) }
        return arr
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
