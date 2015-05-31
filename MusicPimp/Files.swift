//
//  Files.swift
//  MusicPimp
//
//  Created by Michael Skogberg on 23/05/15.
//  Copyright (c) 2015 Skogberg Labs. All rights reserved.
//

import Foundation
class Files {
    static let manager = NSFileManager.defaultManager()
    
    static func exists(path: String) -> Bool {
        return manager.fileExistsAtPath(path)
    }
    static func isDirectory(path: String) -> Bool {
        var isDirectory: ObjCBool = false
        manager.fileExistsAtPath(path, isDirectory: &isDirectory)
        return isDirectory.boolValue
    }
}
