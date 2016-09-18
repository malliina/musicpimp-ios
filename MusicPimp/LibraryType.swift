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
    var rootFolderKey: String { get }
    
    func pingAuth(_ onError: @escaping (PimpError) -> Void, f: @escaping (Version) -> Void)
    
    func rootFolder(_ onError: @escaping (PimpError) -> Void, f: @escaping (MusicFolder) -> Void)
    func folder(_ id: String, onError: @escaping (PimpError) -> Void, f: @escaping (MusicFolder) -> Void)
    func tracks(_ id: String, onError: @escaping (PimpError) -> Void, f: @escaping ([Track]) -> Void)
    func search(_ term: String, onError: @escaping (PimpError) -> Void, ts: @escaping ([Track]) -> Void)
    
    func playlists(_ onError: @escaping (PimpError) -> Void, f: @escaping ([SavedPlaylist]) -> Void)
    func playlist(_ id: PlaylistID, onError: @escaping (PimpError) -> Void, f: @escaping (SavedPlaylist) -> Void)
    func popular(_ from: Int, until: Int, onError: @escaping (PimpError) -> Void, f: @escaping ([PopularEntry]) -> Void)
    func recent(_ from: Int, until: Int, onError: @escaping (PimpError) -> Void, f: @escaping ([RecentEntry]) -> Void)
    func savePlaylist(_ sp: SavedPlaylist, onError: @escaping (PimpError) -> Void, onSuccess: @escaping (PlaylistID) -> Void)
    func deletePlaylist(_ id: PlaylistID, onError: @escaping (PimpError) -> Void, onSuccess: @escaping () -> Void)
    
    func alarms(_ onError: @escaping (PimpError) -> Void, f: @escaping ([Alarm]) -> Void)
    func saveAlarm(_ alarm: Alarm, onError: @escaping (PimpError) -> Void, onSuccess: @escaping () -> Void)
    func deleteAlarm(_ id: AlarmID, onError: @escaping (PimpError) -> Void, onSuccess: @escaping () -> Void)
    func stopAlarm(_ onError: @escaping (PimpError) -> Void, onSuccess: @escaping () -> Void)
    func registerNotifications(_ token: PushToken, tag: String, onError: @escaping (PimpError) -> Void, onSuccess: @escaping () -> Void)
    func unregisterNotifications(_ tag: String, onError: @escaping (PimpError) -> Void, onSuccess: @escaping () -> Void)
}
