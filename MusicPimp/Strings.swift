//
//  Strings.swift
//  MusicPimp
//
//  Created by Michael Skogberg on 12/04/15.
//  Copyright (c) 2015 Skogberg Labs. All rights reserved.
//

import Foundation

extension String {
    func startsWith (_ str: String) -> Bool {
        return self.hasPrefix(str)
    }
    
    func endsWith (_ str: String) -> Bool {
        return self.hasSuffix(str)
    }
    
    func contains (_ str: String) -> Bool {
        return self.range(of: str) == nil
    }
    
    func head() -> Character {
        return self[self.startIndex]
    }
    
    func tail() -> String {
        return String(self.dropFirst())
    }
    
    func lastPathComponent() -> String {
        return (self as NSString).lastPathComponent
    }
    
    func stringByDeletingLastPathComponent() -> String {
        return (self as NSString).deletingLastPathComponent
    }
    
    func stringByDeletingPathExtension() -> String {
        return (self as NSString).deletingPathExtension
    }
    
    func stringByAppendingPathComponent(_ path: String) -> String {
        return (self as NSString).appendingPathComponent(path)
    }
    
}
