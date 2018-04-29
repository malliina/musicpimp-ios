//
//  LibraryType.swift
//  MusicPimp
//
//  Created by Michael Skogberg on 18/05/15.
//  Copyright (c) 2015 Skogberg Labs. All rights reserved.
//

import Foundation
import RxSwift

protocol LibraryType {
    var isLocal: Bool { get }
    var contentsUpdated: Observable<MusicFolder?> { get }
    var rootFolderKey: String { get }
    
    func pingAuth() -> Observable<Version>
    
    func rootFolder() -> Observable<MusicFolder>
    func folder(_ id: String) -> Observable<MusicFolder>
    func tracks(_ id: String) -> Observable<[Track]>
    func search(_ term: String) -> Observable<[Track]>
    
    func playlists() -> Observable<[SavedPlaylist]>
    func playlist(_ id: PlaylistID) -> Observable<SavedPlaylist>
    func popular(_ from: Int, until: Int) -> Observable<[PopularEntry]>
    func recent(_ from: Int, until: Int) -> Observable<[RecentEntry]>
    func savePlaylist(_ sp: SavedPlaylist) -> Observable<PlaylistID>
    func deletePlaylist(_ id: PlaylistID) -> Observable<HttpResponse>
    
    func alarms() -> Observable<[Alarm]>
    func saveAlarm(_ alarm: Alarm) -> Observable<HttpResponse>
    func deleteAlarm(_ id: AlarmID) -> Observable<HttpResponse>
    func stopAlarm() -> Observable<HttpResponse>
    func registerNotifications(_ token: PushToken, tag: String) -> Observable<HttpResponse>
    func unregisterNotifications(_ tag: String) -> Observable<HttpResponse>
}
