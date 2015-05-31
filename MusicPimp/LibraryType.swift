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
    func pingAuth(onError: PimpError -> Void, f: Version -> Void)
    func folder(id: String, onError: PimpError -> Void, f: MusicFolder -> Void)
    func rootFolder(onError: PimpError -> Void, f: MusicFolder -> Void)
    func tracks(id: String, onError: PimpError -> Void, f: [Track] -> Void)
    func urlFor(trackID: String) -> NSURL
}
