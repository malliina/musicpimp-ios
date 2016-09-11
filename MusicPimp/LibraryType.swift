//
//  LibraryType.swift
//  MusicPimp
//
//  Created by Michael Skogberg on 18/05/15.
//  Copyright (c) 2015 Skogberg Labs. All rights reserved.
//

import Foundation

protocol LibraryType {
    var isLocal: Bool { get }
    var contentsUpdated: Event<MusicFolder?> { get }
    
    func pingAuth(onError: PimpError -> Void, f: Version -> Void)
    
    func rootFolder(onError: PimpError -> Void, f: MusicFolder -> Void)
    func folder(id: String, onError: PimpError -> Void, f: MusicFolder -> Void)
    func tracks(id: String, onError: PimpError -> Void, f: [Track] -> Void)
    func search(term: String, onError: PimpError -> Void, ts: [Track] -> Void)
    
    func playlists(onError: PimpError -> Void, f: [SavedPlaylist] -> Void)
    func playlist(id: PlaylistID, onError: PimpError -> Void, f: SavedPlaylist -> Void)
    func popular(from: Int, until: Int, onError: PimpError -> Void, f: [PopularEntry] -> Void)
    func recent(from: Int, until: Int, onError: PimpError -> Void, f: [RecentEntry] -> Void)
    func savePlaylist(sp: SavedPlaylist, onError: PimpError -> Void, onSuccess: PlaylistID -> Void)
    func deletePlaylist(id: PlaylistID, onError: PimpError -> Void, onSuccess: () -> Void)
    
    func alarms(onError: PimpError -> Void, f: [Alarm] -> Void)
    func saveAlarm(alarm: Alarm, onError: PimpError -> Void, onSuccess: () -> Void)
    func deleteAlarm(id: AlarmID, onError: PimpError -> Void, onSuccess: () -> Void)
    func stopAlarm(onError: PimpError -> Void, onSuccess: () -> Void)
    func registerNotifications(token: PushToken, tag: String, onError: PimpError -> Void, onSuccess: () -> Void)
    func unregisterNotifications(tag: String, onError: PimpError -> Void, onSuccess: () -> Void)
}
