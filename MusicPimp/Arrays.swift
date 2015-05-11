//
//  Arrays.swift
//  MusicPimp
//
//  Created by Michael Skogberg on 26/04/15.
//  Copyright (c) 2015 Skogberg Labs. All rights reserved.
//

import Foundation

extension Array {
    func headOption() -> T? {
        return self.first
    }
    func tail() -> [T] {
        return Array(self[1..<self.count])
    }
    func take(n: Int) -> [T] {
        return Array(self[0..<n])
    }
    func drop(n: Int) -> [T] {
        return Array(self[n..<self.count])
    }
    func find(predicate: T -> Bool) -> T? {
        return self.filter(predicate).headOption()
    }
    func exists(predicate: T -> Bool) -> Bool {
        return self.find(predicate) != nil
    }
    func indexOf(predicate: T -> Bool) -> Int? {
        for (idx, element) in enumerate(self) {
            if predicate(element) {
                return idx
            }
        }
        return nil
    }
}
