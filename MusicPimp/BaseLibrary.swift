//
//  BaseLibrary.swift
//  MusicPimp
//
//  Created by Michael Skogberg on 24/05/15.
//  Copyright (c) 2015 Skogberg Labs. All rights reserved.
//

import Foundation
open class BaseLibrary: LibraryType {
    var isLocal: Bool { get { return false } }
    var rootFolderKey: String { get { return "" } }
    let contentsUpdated = Event<MusicFolder?>()
    
    let notImplementedError = PimpError.simpleError(ErrorMessage(message: "Not implemented yet"))
    
    func pingAuth(_ onError: @escaping (PimpError) -> Void, f: @escaping (Version) -> Void) {
        
    }
    
    func folder(_ id: String, onError: @escaping (PimpError) -> Void, f: @escaping (MusicFolder) -> Void) {
        
    }
    
    func rootFolder(_ onError: @escaping (PimpError) -> Void, f: @escaping (MusicFolder) -> Void) {
        
    }
    
    func tracks(_ id: String, onError: @escaping (PimpError) -> Void, f: @escaping ([Track]) -> Void) {
        tracksInner(id,  others: [], acc: [], f: f, onError: onError)
    }
    
    // the saved playlists
    func playlists(_ onError: @escaping (PimpError) -> Void, f: @escaping ([SavedPlaylist]) -> Void) {
        f([])
    }
    
    func playlist(_ id: PlaylistID, onError: @escaping (PimpError) -> Void, f: @escaping (SavedPlaylist) -> Void) {
        onError(notImplementedError)
    }
    
    func popular(_ from: Int, until: Int, onError: @escaping (PimpError) -> Void, f: @escaping ([PopularEntry]) -> Void) {
        onError(notImplementedError)
    }
    
    func recent(_ from: Int, until: Int, onError: @escaping (PimpError) -> Void, f: @escaping ([RecentEntry]) -> Void) {
        onError(notImplementedError)
    }
    
    func savePlaylist(_ sp: SavedPlaylist, onError: @escaping (PimpError) -> Void, onSuccess: @escaping (PlaylistID) -> Void) {
        onError(notImplementedError)
    }
    
    func deletePlaylist(_ id: PlaylistID, onError: @escaping (PimpError) -> Void, onSuccess: @escaping () -> Void) {
        onSuccess()
    }
    
    func search(_ term: String, onError: @escaping (PimpError) -> Void, ts: @escaping ([Track]) -> Void) {
        ts([])
    }
    
    func alarms(_ onError: @escaping (PimpError) -> Void, f: @escaping ([Alarm]) -> Void) {
        f([])
    }
    
    func saveAlarm(_ alarm: Alarm, onError: @escaping (PimpError) -> Void, onSuccess: @escaping () -> Void) {
        onSuccess()
    }
    
    func deleteAlarm(_ id: AlarmID, onError: @escaping (PimpError) -> Void, onSuccess: @escaping () -> Void) {
        onSuccess()
    }
    
    func stopAlarm(_ onError: @escaping (PimpError) -> Void, onSuccess: @escaping () -> Void) {
        onSuccess()
    }
    
    func registerNotifications(_ token: PushToken, tag: String, onError: @escaping (PimpError) -> Void, onSuccess: @escaping () -> Void) {
        onSuccess()
    }
    
    func unregisterNotifications(_ tag: String, onError: @escaping (PimpError) -> Void, onSuccess: @escaping () -> Void) {
        onSuccess()
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
}
