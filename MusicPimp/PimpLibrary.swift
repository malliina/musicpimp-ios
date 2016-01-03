//
//  PimpLibrary.swift
//  MusicPimp
//
//  Created by Michael Skogberg on 23/05/15.
//  Copyright (c) 2015 Skogberg Labs. All rights reserved.
//

import Foundation

public class PimpLibrary: BaseLibrary {
    let endpoint: Endpoint
    let client: PimpHttpClient
    let helper: PimpUtils
    
    init(endpoint: Endpoint, client: PimpHttpClient) {
        self.endpoint = endpoint
        self.client = client
        self.helper = PimpUtils(endpoint: endpoint)
    }

    override func pingAuth(onError: PimpError -> Void, f: Version -> Void) {
        client.pingAuth(onError, f: f)
    }
    
    override func rootFolder(onError: PimpError -> Void, f: MusicFolder -> Void) {
        client.pimpGetParsed(Endpoints.FOLDERS, parse: parseMusicFolder, f: f, onError: onError)
    }
    
    override func folder(id: String, onError: PimpError -> Void, f: MusicFolder -> Void) {
        client.pimpGetParsed("\(Endpoints.FOLDERS)/\(id)", parse: parseMusicFolder, f: f, onError: onError)
    }
    
    override func tracks(id: String, onError: PimpError -> Void, f: [Track] -> Void) {
        tracksInner(id,  others: [], acc: [], f: f, onError: onError)
    }
    
    override func playlists(onError: PimpError -> Void, f: [SavedPlaylist] -> Void) {
        client.pimpGetParsed("\(Endpoints.PLAYLISTS)", parse: parsePlaylists, f: f, onError: onError)
    }
    
    override func playlist(id: PlaylistID, onError: PimpError -> Void, f: SavedPlaylist -> Void) {
        client.pimpGetParsed("\(Endpoints.PLAYLISTS)\(id.id)", parse: parseGetPlaylistResponse, f: f, onError: onError)
    }
    
    override func savePlaylist(sp: SavedPlaylist, onError: PimpError -> Void, onSuccess: PlaylistID -> Void) {
        let json = [
            JsonKeys.PLAYLIST: SavedPlaylist.toJson(sp)
        ]
        Log.info("Posting \(json)")
        client.pimpPost("\(Endpoints.PLAYLISTS)", payload: json, f: { (data) -> Void in
            Log.info("Posted")
            if let jsonObj = Json.asJson(data), id = self.parsePlaylistID(jsonObj) {
                onSuccess(id)
            } else {
                onError(PimpError.SimpleError(ErrorMessage(message: "Response parsing failed, got \(data)")))
            }
            }, onError: onError)
    }
    
    override func deletePlaylist(id: PlaylistID, onError: PimpError -> Void, onSuccess: () -> Void) {
        client.pimpPost("\(Endpoints.PLAYLIST_DELETE)/\(id.id)", payload: [:], f: { (data) -> Void in
            Log.info("Deleted \(id)")
            onSuccess(())
            }, onError: onError)
    }
    
    override func search(term: String, onError: PimpError -> Void, ts: [Track] -> Void) {
        client.pimpGetParsed("\(Endpoints.SEARCH)?term=\(term)", parse: parseTracks, f: ts, onError: onError)
    }
    
    override func alarms(onError: PimpError -> Void, f: [Alarm] -> Void) {
        client.pimpGetParsed(Endpoints.ALARMS, parse: parseAlarms, f: f, onError: onError)
    }
    
    override func saveAlarm(alarm: Alarm, onError: PimpError -> Void, onSuccess: () -> Void) {
        let payload: [String: AnyObject] = [
            JsonKeys.CMD: JsonKeys.Save,
            JsonKeys.Ap: Alarm.toJson(alarm),
            JsonKeys.Enabled: alarm.enabled
        ]
        client.pimpPost(Endpoints.ALARMS, payload: payload, f: { (data) -> Void in
            if alarm.id == nil {
                Log.info("Created new alarm")
            } else {
                Log.info("Saved alarm \(alarm.id)")
            }
            onSuccess(())
            }, onError: onError)
    }
    
    override func deleteAlarm(id: AlarmID, onError: PimpError -> Void, onSuccess: () -> Void) {
        let payload = [
            JsonKeys.CMD : JsonKeys.DELETE,
            JsonKeys.ID : id.id
        ]
        alarmsPost(payload, onError: onError, onSuccess: onSuccess)
    }
    
    override func stopAlarm(onError: PimpError -> Void, onSuccess: () -> Void) {
        let payload = [
            JsonKeys.CMD: JsonKeys.STOP
        ]
        alarmsPost(payload, onError: onError, onSuccess: onSuccess)
    }
    
    override func registerNotifications(token: PushToken, tag: String, onError: PimpError -> Void, onSuccess: () -> Void) {
        let payload = [
            JsonKeys.CMD: JsonKeys.ApnsAdd,
            JsonKeys.Id: token.token,
            JsonKeys.ApnsTag: tag
        ]
        alarmsPost(payload, onError: onError, onSuccess: onSuccess)
    }
    
    override func unregisterNotifications(tag: String, onError: PimpError -> Void, onSuccess: () -> Void) {
        let payload = [
            JsonKeys.CMD: JsonKeys.ApnsRemove,
            JsonKeys.Id: tag
        ]
        alarmsPost(payload, onError: onError, onSuccess: onSuccess)
    }
    
    private func alarmsPost(payload: [String: AnyObject], onError: PimpError -> Void, onSuccess: () -> Void) {
        client.pimpPost(Endpoints.ALARMS, payload: payload, f: { (data) -> Void in
            onSuccess(())
            }, onError: onError)
    }
    
    private func tracksInner(id: String, others: [String], acc: [Track], f: [Track] -> Void, onError: PimpError -> Void){
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
    
    func parseFolder(obj: NSDictionary) -> Folder? {
        if let id = obj[JsonKeys.ID] as? String,
            title = obj[JsonKeys.TITLE] as? String,
            path = obj[JsonKeys.PATH] as? String {
                return Folder(
                    id: id,
                    title: title,
                    path: path)
        }
        return nil
    }
    
    func parseTrack(dict: NSDictionary) -> Track? {
        return PimpEndpoint.parseTrack(dict, urlMaker: { (id) -> NSURL in self.helper.urlFor(id) })
    }

    func parseMusicFolder(obj: AnyObject) -> MusicFolder? {
        if let dict = obj as? NSDictionary,
            folderJSON = dict[JsonKeys.FOLDER] as? NSDictionary,
            foldersJSON = dict[JsonKeys.FOLDERS] as? NSArray,
            tracksJSON = dict[JsonKeys.TRACKS] as? NSArray,
            root = parseFolder(folderJSON) {
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
    
    func parsePlaylists(obj: AnyObject) -> [SavedPlaylist] {
//        Log.info("Playlist \(obj)")
        if let obj = obj as? NSDictionary,
            playlistsArr = obj[JsonKeys.PLAYLISTS] as? [NSDictionary] {
            return playlistsArr.flatMapOpt(parsePlaylist)
        } else {
            return []
        }
    }
    
    func parseGetPlaylistResponse(obj: AnyObject) -> SavedPlaylist? {
        if let obj = obj as? NSDictionary, playlistObj = obj[JsonKeys.PLAYLIST] as? NSDictionary {
            return parsePlaylist(playlistObj)
        } else {
            return nil
        }
    }
    
    func parsePlaylist(obj: AnyObject) -> SavedPlaylist? {
        if let obj = obj as? NSDictionary,
            id = obj[JsonKeys.ID] as? Int,
            name = obj[JsonKeys.NAME] as? String,
            tracksArr = obj[JsonKeys.TRACKS] as? [NSDictionary] {
            let tracks = tracksArr.flatMapOpt(parseTrack)
                return SavedPlaylist(id: PlaylistID(id: id), name: name, tracks: tracks)
        } else {
            return nil
        }
    }
    
    func parsePlaylistID(obj: AnyObject) -> PlaylistID? {
        if let obj = obj as? NSDictionary, id = obj[JsonKeys.ID] as? Int {
            return PlaylistID(id: id)
        } else {
            return nil
        }
    }
    
    func parseTracks(obj: AnyObject) -> [Track]? {
        if let arr = obj as? [NSDictionary] {
            let tracks = arr.flatMapOpt(parseTrack)
            return tracks
        }
        Log.info("Unable to parse tracks from \(obj)")
        return nil
    }
    
    func parseAlarms(obj: AnyObject) -> [Alarm] {
        if let arr = obj as? [NSDictionary] {
            return arr.flatMapOpt(parseAlarm)
        } else {
            return []
        }
    }
    
    func parseAlarm(dict: NSDictionary) -> Alarm? {
        if let id = dict[JsonKeys.ID] as? String,
            job = dict[JsonKeys.JOB] as? NSDictionary,
            trackDict = job[JsonKeys.TRACK] as? NSDictionary,
            track = parseTrack(trackDict),
            when = dict[JsonKeys.WHEN] as? NSDictionary,
            hour = when[JsonKeys.Hour] as? Int,
            minute = when[JsonKeys.Minute] as? Int,
            dayNames = when[JsonKeys.Days] as? [String],
            enabled = dict[JsonKeys.Enabled] as? Bool {
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