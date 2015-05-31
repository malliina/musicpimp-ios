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
        let to = min(n, self.count)
        return Array(self[0..<to])
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
    func flatMapOpt<U>(f: T -> U?) -> [U] {
        return self.map({ f($0) }).filter({ $0 != nil}).map({ $0! })
    }
    func partition(f: T -> Bool) -> ([T], [T]) {
        var trues: [T] = []
        var falses: [T] = []
        for item in self {
            if f(item) {
                trues.append(item)
            } else {
                falses.append(item)
            }
        }
        return (trues, falses)
    }
//    func mkString(sep: String) -> String {
//        var ret = ""
//        for (idx, element) in enumerate(self) {
//            ret += element
//            let isLast = idx == self.count-1
//            if !isLast {
//                ret += sep
//            }
//        }
//        return ret
//    }
}
