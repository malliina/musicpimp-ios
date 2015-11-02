//
//  Folder.swift
//  MusicPimp
//
//  Created by Michael Skogberg on 02/11/15.
//  Copyright © 2015 Skogberg Labs. All rights reserved.
//

import Foundation

class Folder: MusicItem {
    static let empty = Folder(id: "", title: "", path: "")
    static let root = empty
    
    let path: String
    
    init(id: String, title: String, path: String) {
        self.path = path
        super.init(id: id, title: title)
    }
}
