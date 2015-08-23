//
//  Arrays.swift
//  MusicPimp
//
//  Created by Michael Skogberg on 26/04/15.
//  Copyright (c) 2015 Skogberg Labs. All rights reserved.
//

import Foundation

extension Array {
    //
    // [1, 2, 3].foldRight(0)((e, acc) -> e + acc)
    // 1 + [2, 3].foldRight(0)((e, acc) -> e + acc)
    // 1 + (2 + [3].foldRight(0)((e, acc) -> e + acc))
    // 1 + (2 + (3 + [].foldRight(0)((e, acc) -> e + acc)))
    // 1 + (2 + (3 + (0)))
    // 6
    //
    func foldRight<U>(initial: U, f: (T, U) -> U) -> U {
        if let head = self.headOption() {
            return f(head, self.tail().foldRight(initial, f: f))
        } else {
            return initial
        }
    }
    
    //
    // [1, 2, 3].foldLeft(0)((acc, e) -> acc + e)
    // [2, 3].foldLeft(1)((acc, e) -> acc + e)
    // [3].foldLeft(3)((acc, e) -> acc + e)
    // [].foldLeft(6)((acc, e) -> acc + e)
    // 6
    //
    func foldLeft<U>(initial: U, f: (U, T) -> U) -> U {
        if let head = self.headOption() {
            let newAcc = f(initial, head)
            return self.tail().foldLeft(newAcc, f: f)
        } else {
            return initial
        }
    }
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
    func mkString(sep: String) -> String {
        return mkString("", sep: sep, suffix: "")
    }
    func mkString(prefix: String, sep: String, suffix: String) -> String {
        let count = self.count
        var ret = count > 0 ? prefix : ""
        for (idx, element) in enumerate(self) {
            ret += "\(element)"
            let isLast = idx == count - 1
            if isLast {
                ret += suffix
            } else {
                ret += sep
            }
        }
        return ret
    }
}

// http://stackoverflow.com/questions/24116271/whats-the-cleanest-way-of-applying-map-to-a-dictionary-in-swift
extension Dictionary {
    init(_ pairs: [Element]) {
        self.init()
        for (k, v) in pairs {
            self[k] = v
        }
    }
    
    func mapValues<OutValue>(transform: Value -> OutValue) -> [Key: OutValue] {
        return self.map { (key, value) -> (Key, OutValue) in
            (key, transform(value))
        }
    }
    
    func map<OutKey: Hashable, OutValue>(transform: Element -> (OutKey, OutValue)) -> [OutKey: OutValue] {
        let pairs = Swift.map(self) { (e) in (transform(e)) }
        return Dictionary<OutKey, OutValue>(pairs)
    }

    func filter(includeElement: Element -> Bool) -> [Key: Value] {
        let pairs = Swift.filter(self, includeElement)
        return Dictionary(pairs)
    }
}
