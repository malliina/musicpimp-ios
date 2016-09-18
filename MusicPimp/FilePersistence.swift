//
//  Files.swift
//  MusicPimp
//
//  Created by Michael Skogberg on 08/05/15.
//  Copyright (c) 2015 Skogberg Labs. All rights reserved.
//

import Foundation

class FilePersistence : Persistence {
    
    let dir = NSSearchPathForDirectoriesInDomains(FileManager.SearchPathDirectory.documentDirectory, FileManager.SearchPathDomainMask.userDomainMask, true)[0]
    
    let changes = Event<Setting>()
    
    // are you fucking kidding me?
    func load(_ path: String) -> String? {
        let file = dir.stringByAppendingPathComponent(path)
        var loadError: NSError?
        do {
            let contents = try NSString(contentsOfFile: file, encoding: String.Encoding.utf8.rawValue)
            if let _ = loadError {
                return nil
            } else {
                return contents as String
            }
        } catch let error as NSError {
            loadError = error
            return nil
        }
    }
    
    
    func save(_ contents: String, key: String) -> ErrorMessage? {
        let file = dir.stringByAppendingPathComponent(key)
        var saveError: NSError?
        let written: Bool
        do {
            try contents.write(toFile: file, atomically: true, encoding: String.Encoding.utf8)
            written = true
        } catch let error as NSError {
            saveError = error
            written = false
        }
        if(written) {
            changes.raise(Setting(key: key, contents: contents))
            return nil
        } else {
            return ErrorMessage(message: saveError?.localizedDescription ?? "Unknown error")
        }
    }
}
