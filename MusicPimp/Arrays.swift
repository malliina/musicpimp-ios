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
    func foldRight<U>(initial: U, f: (Element, U) -> U) -> U {
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
    func foldLeft<U>(initial: U, f: (U, Element) -> U) -> U {
        if let head = self.headOption() {
            let newAcc = f(initial, head)
            return self.tail().foldLeft(newAcc, f: f)
        } else {
            return initial
        }
    }
    func headOption() -> Element? {
        return self.first
    }
    func tail() -> [Element] {
        return Array(self[1..<self.count])
    }
    func take(n: Int) -> [Element] {
        let to = min(n, self.count)
        return Array(self[0..<to])
    }
    func drop(n: Int) -> [Element] {
        return Array(self[n..<self.count])
    }
    func find(predicate: Element -> Bool) -> Element? {
        return self.filter(predicate).headOption()
    }
    func exists(predicate: Element -> Bool) -> Bool {
        return self.find(predicate) != nil
    }
    func indexOf(predicate: Element -> Bool) -> Int? {
        for (idx, element) in self.enumerate() {
            if predicate(element) {
                return idx
            }
        }
        return nil
    }
    func flatMapOpt<U>(f: Element -> U?) -> [U] {
        return self.map({ f($0) }).filter({ $0 != nil}).map({ $0! })
    }
    func partition(f: Element -> Bool) -> ([Element], [Element]) {
        var trues: [Element] = []
        var falses: [Element] = []
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
        for (idx, element) in self.enumerate() {
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
        return self.map { (e) in (transform(e)) }
    }

    func filterKeys(includeElement: Element -> Bool) -> [Key: Value] {
        let pairs = self.filter(includeElement)
        return Dictionary<Key, Value>(pairs)
    }
}
