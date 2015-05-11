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
        return self.substringFromIndex(advance(self.startIndex, 1))
    }
    
    func dropLast() -> String {
        let endIndex = advance(self.endIndex, -1)
        return self.substringToIndex(endIndex)
    }
}
