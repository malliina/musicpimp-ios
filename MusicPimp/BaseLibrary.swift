//
//  BaseLibrary.swift
//  MusicPimp
//
//  Created by Michael Skogberg on 24/05/15.
//  Copyright (c) 2015 Skogberg Labs. All rights reserved.
//

import Foundation
import RxSwift

open class BaseLibrary: LibraryType {
    var isLocal: Bool { get { return false } }
    var rootFolderKey: String { get { return "" } }
    let contentsUpdated = Event<MusicFolder?>()
    
    let notImplementedError = PimpError.simpleError(ErrorMessage(message: "Not implemented yet"))
    
    func pingAuth() -> Observable<Version> {
        return Observable.empty()
    }
    
    func folder(_ id: String) -> Observable<MusicFolder> {
        return Observable.empty()
    }
    
    func rootFolder() -> Observable<MusicFolder> {
        return Observable.empty()
    }
    
    func tracks(_ id: String) -> Observable<[Track]> {
        return tracksInner(id,  others: [], acc: [])
    }
    
    // the saved playlists
    func playlists() -> Observable<[SavedPlaylist]> {
        return Observable.just([])
    }
    
    func playlist(_ id: PlaylistID) -> Observable<SavedPlaylist> {
        return Observable.error(notImplementedError)
    }
    
    func popular(_ from: Int, until: Int) -> Observable<[PopularEntry]> {
        return Observable.error(notImplementedError)
    }
    
    func recent(_ from: Int, until: Int) -> Observable<[RecentEntry]> {
        return Observable.error(notImplementedError)
    }
    
    func savePlaylist(_ sp: SavedPlaylist) -> Observable<PlaylistID> {
        return Observable.error(notImplementedError)
    }
    
    func deletePlaylist(_ id: PlaylistID) -> Observable<HttpResponse> {
        return Observable.error(notImplementedError)
    }
    
    func search(_ term: String) -> Observable<[Track]> {
        return Observable.just([])
    }
    
    func alarms() -> Observable<[Alarm]> {
        return Observable.just([])
    }
    
    func saveAlarm(_ alarm: Alarm) -> Observable<HttpResponse> {
        return Observable.error(notImplementedError)
    }
    
    func deleteAlarm(_ id: AlarmID) -> Observable<HttpResponse> {
        return Observable.error(notImplementedError)
    }
    
    func stopAlarm() -> Observable<HttpResponse> {
        return Observable.error(notImplementedError)
    }
    
    func registerNotifications(_ token: PushToken, tag: String) -> Observable<HttpResponse> {
        return Observable.error(notImplementedError)
    }
    
    func unregisterNotifications(_ tag: String) -> Observable<HttpResponse> {
        return Observable.error(notImplementedError)
    }
    
    func tracksInner(_ id: String, others: [String], acc: [Track]) -> Observable<[Track]> {
        return folder(id).flatMap { (result) -> Observable<[Track]> in
            let subIDs = result.folders.map { $0.id }
            let remaining = others + subIDs
            let newAcc = acc + result.tracks
            if let head = remaining.first {
                let tail = remaining.tail()
                return self.tracksInner(head, others: tail, acc: newAcc)
            } else {
                return Observable.just(newAcc)
            }
        }
    }
}
