//
//  Arrays.swift
//  MusicPimp
//
//  Created by Michael Skogberg on 26/04/15.
//  Copyright (c) 2015 Skogberg Labs. All rights reserved.
//

import Foundation

class Arrays {
    static func move<T>(_ srcIndex: Int, destIndex: Int, xs: [T]) -> [T] {
        var newXs = xs
        let passenger = newXs.remove(at: srcIndex)
        newXs.insert(passenger, at: destIndex)
        return newXs
    }
}

extension Array {
    //
    // [1, 2, 3].foldRight(0)((e, acc) -> e + acc)
    // 1 + [2, 3].foldRight(0)((e, acc) -> e + acc)
    // 1 + (2 + [3].foldRight(0)((e, acc) -> e + acc))
    // 1 + (2 + (3 + [].foldRight(0)((e, acc) -> e + acc)))
    // 1 + (2 + (3 + (0)))
    // 6
    //
    func foldRight<U>(_ initial: U, f: (Element, U) -> U) -> U {
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
    func foldLeft<U>(_ initial: U, f: (U, Element) -> U) -> U {
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
    
    func get(_ index: Int) -> Element? {
        if count > index {
            return self[index]
        } else {
            return nil
        }
    }
    
    func take(_ n: Int) -> [Element] {
        let to = [n, self.count].min() ?? 0
        return Array(self[0..<to])
    }
    
    func drop(_ n: Int) -> [Element] {
        return Array(self[n..<self.count])
    }
    
    func find(_ predicate: (Element) -> Bool) -> Element? {
        return self.filter(predicate).headOption()
    }
    
    func exists(_ predicate: (Element) -> Bool) -> Bool {
        return self.find(predicate) != nil
    }
    
    func howMany(_ predicate: (Element) -> Bool) -> Int {
        return self.filter(predicate).count
    }
    
    func indexOf(_ predicate: (Element) -> Bool) -> Int? {
        for (idx, element) in self.enumerated() {
            if predicate(element) {
                return idx
            }
        }
        return nil
    }
    
    func flatMapOpt<U>(_ f: (Element) -> U?) -> [U] {
        return self.map({ f($0) }).filter({ $0 != nil}).map({ $0! })
    }
    
    func partition(_ f: (Element) -> Bool) -> ([Element], [Element]) {
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
    
    func mkString(_ sep: String) -> String {
        return mkString("", sep: sep, suffix: "")
    }
    
    func mkString(_ prefix: String, sep: String, suffix: String) -> String {
        let count = self.count
        var ret = count > 0 ? prefix : ""
        for (idx, element) in self.enumerated() {
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

    func filterKeys(_ includeElement: (Element) -> Bool) -> [Key: Value] {
        return self.filter(includeElement)
    }
    
    func addAll(_ other: [Key: Value]) -> [Key: Value] {
        var combined = Dictionary<Key, Value>()
        for(k, v) in self {
            combined.updateValue(v, forKey: k)
        }
        for(key, value) in other {
            combined.updateValue(value, forKey: key)
        }
        return combined
    }
}
