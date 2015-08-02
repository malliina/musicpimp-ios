//
//  Files.swift
//  MusicPimp
//
//  Created by Michael Skogberg on 08/05/15.
//  Copyright (c) 2015 Skogberg Labs. All rights reserved.
//

import Foundation

class FilePersistence : Persistence {
    
    let dir = NSSearchPathForDirectoriesInDomains(NSSearchPathDirectory.DocumentDirectory, NSSearchPathDomainMask.UserDomainMask, true)[0] as? String
    
    let changes = Event<Setting>()
    
    // are you fucking kidding me?
    func load(path: String) -> String? {
        if let file = dir?.stringByAppendingPathComponent(path) {
            var loadError: NSError?
            if let contents = NSString(contentsOfFile: file, encoding: NSUTF8StringEncoding, error: &loadError) {
                if let error = loadError {
                    return nil
                } else {
                    return contents as String
                }
            } else {
                return nil
            }
        } else {
            return nil
        }
    }
    
    
    func save(contents: String, key: String) -> ErrorMessage? {
        if let file = dir?.stringByAppendingPathComponent(key) {
            var saveError: NSError?
            let written = contents.writeToFile(file, atomically: true, encoding: NSUTF8StringEncoding, error: &saveError)
            if(written) {
                changes.raise(Setting(key: key, contents: contents))
                return nil
            } else {
                return ErrorMessage(message: saveError?.localizedDescription ?? "Unknown error")
            }
        } else {
            return ErrorMessage(message: "Unable to resolve \(key)")
        }
    }
}
