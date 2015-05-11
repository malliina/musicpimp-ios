//
//  UserPrefs.swift
//  MusicPimp
//
//  Created by Michael Skogberg on 11/05/15.
//  Copyright (c) 2015 Skogberg Labs. All rights reserved.
//
import Foundation

class UserPrefs: Persistence {
    static let sharedInstance = UserPrefs()
    
    let prefs = NSUserDefaults.standardUserDefaults()
    
    func save(contents: String, key: String) -> String? {
        prefs.setObject(contents, forKey: key)
        Log.info("Saved \(contents) to \(key)")
        return nil
    }
    
    func load(key: String) -> String? {
        return prefs.stringForKey(key)
    }
}
