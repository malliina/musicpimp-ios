//
//  Strings.swift
//  MusicPimp
//
//  Created by Michael Skogberg on 12/04/15.
//  Copyright (c) 2015 Skogberg Labs. All rights reserved.
//

import Foundation

extension String {
    func startsWith (str: String) -> Bool {
        return self.hasPrefix(str)
    }
    
    func endsWith (str: String) -> Bool {
        return self.hasSuffix(str)
    }
    
    func contains (str: String) -> Bool {
        return self.rangeOfString(str) == nil
    }
    
    func head() -> Character {
        return self[self.startIndex]
    }
    
    func tail() -> String {
        return self.substringFromIndex(self.startIndex.advancedBy(1))
    }
    
    func dropLast() -> String {
        let endIndex = self.endIndex.advancedBy(-1)
        return self.substringToIndex(endIndex)
    }
    
    func lastPathComponent() -> String {
        return (self as NSString).lastPathComponent
    }
    
    func stringByDeletingLastPathComponent() -> String {
        return (self as NSString).stringByDeletingLastPathComponent
    }
    
    func stringByDeletingPathExtension() -> String {
        return (self as NSString).stringByDeletingPathExtension
    }
    
    func stringByAppendingPathComponent(path: String) -> String {
        return (self as NSString).stringByAppendingPathComponent(path)
    }
    
}
