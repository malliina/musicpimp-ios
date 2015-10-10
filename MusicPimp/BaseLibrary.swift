//
//  BaseLibrary.swift
//  MusicPimp
//
//  Created by Michael Skogberg on 24/05/15.
//  Copyright (c) 2015 Skogberg Labs. All rights reserved.
//

import Foundation
class BaseLibrary: LibraryType {
    var isLocal: Bool { get { return false } }
    let contentsUpdated = Event<MusicFolder?>()
    
    func pingAuth(onError: PimpError -> Void, f: Version -> Void) {
        
    }
    
    func folder(id: String, onError: PimpError -> Void, f: MusicFolder -> Void) {
        
    }
    
    func rootFolder(onError: PimpError -> Void, f: MusicFolder -> Void) {
        
    }
    
    func tracks(id: String, onError: PimpError -> Void, f: [Track] -> Void) {
        tracksInner(id,  others: [], acc: [], f: f, onError: onError)
    }
    
    func search(term: String, onError: PimpError -> Void, ts: [Track] -> Void) {
        ts([])
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
}
