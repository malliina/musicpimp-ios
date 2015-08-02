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
    let changes = Event<Setting>()
    
    func save(contents: String, key: String) -> ErrorMessage? {
        prefs.setObject(contents, forKey: key)
        Log.info("Saved \(contents) to \(key)")
        changes.raise(Setting(key: key, contents: contents))
        return nil
    }
    
    func load(key: String) -> String? {
        return prefs.stringForKey(key)
    }
}

class Setting {
    let key: String
    let contents: String
    init(key: String, contents: String) {
        self.key = key
        self.contents = contents
    }
}
