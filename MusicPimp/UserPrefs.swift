//
//  UserPrefs.swift
//  MusicPimp
//
//  Created by Michael Skogberg on 11/05/15.
//  Copyright (c) 2015 Skogberg Labs. All rights reserved.
//
import Foundation

open class UserPrefs: Persistence {
    let log = LoggerFactory.system("UserPrefs")
    static let sharedInstance = UserPrefs()
    
    let prefs = UserDefaults.standard
    let changes = Event<Setting>()
    
    func save(_ contents: String, key: String) -> ErrorMessage? {
        prefs.set(contents, forKey: key)
//        log.info("Saved \(contents) to \(key)")
        changes.raise(Setting(key: key, contents: contents))
        return nil
    }
    
    func load(_ key: String) -> String? {
        return prefs.string(forKey: key)
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
