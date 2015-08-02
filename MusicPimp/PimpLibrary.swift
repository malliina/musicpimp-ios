//
//  PimpLibrary.swift
//  MusicPimp
//
//  Created by Michael Skogberg on 23/05/15.
//  Copyright (c) 2015 Skogberg Labs. All rights reserved.
//

import Foundation
class PimpLibrary: BaseLibrary {
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
}