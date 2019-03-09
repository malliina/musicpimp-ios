//
//  Duration.swift
//  MusicPimp
//
//  Created by Michael Skogberg on 27/06/15.
//  Copyright (c) 2015 Skogberg Labs. All rights reserved.
//

import Foundation

protocol SecondsCodable: Codable {
    init(seconds: Int64)
    var seconds: Int64 { get }
}

extension SecondsCodable {
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let raw = try container.decode(Int64.self)
        self.init(seconds: raw)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(seconds)
    }
}

struct Duration: CustomStringConvertible, Comparable, SecondsCodable {
    static let Zero = Duration(millis: 0)
    let millis: Int64
    var secondsFloat: Float { get { return Float(seconds) } }
    var seconds: Int64 { get { return self.millis / 1000 } }
    var minutes: Int64 { get { return self.millis / 60000 } }
    var hours: Int64 { get { return self.millis / 3600000 } }
    
    init(millis: Int64) {
        self.millis = millis
    }
    
    init(ms: UInt) {
        self.init(millis: Int64(ms))
    }
    
    init(seconds: Int64)  {
        self.init(millis: seconds * 1000)
    }
    
    init(secs: UInt)  {
        self.init(millis: Int64(secs * 1000))
    }
    
    init(minutes: UInt) {
        self.init(secs: minutes * 60)
    }
    
    init(hours: UInt) {
        self.init(minutes: hours * 60)
    }
    
    static func now() -> Duration {
        // can this fail?
        return Date().timeIntervalSince1970.seconds!
    }
    
    fileprivate func toReadable(_ duration: Duration) -> String {
        let hours = countHours(duration)
        let hs = padded(hours)
        let mins = padded(countMinutes(duration))
        let secs = padded(countSeconds(duration))
        if hours > 0 {
            return "\(hs):\(mins):\(secs)"
        } else {
            return "\(mins):\(secs)"
        }
    }
    
    fileprivate func padded(_ time: Int64) -> String {
        return time < 10 ? "0\(time)" : "\(time)"
    }
    
    fileprivate func countSeconds(_ time: Duration) -> Int64 {
        return time.seconds % 60
    }
    
    fileprivate func countMinutes(_ time: Duration) -> Int64 {
        return time.minutes % 60
    }
    
    fileprivate func countHours(_ time: Duration) -> Int64 {
        return time.seconds / 3600
    }
    
    var description: String { get { return toReadable(self) } }
    
    public static func ==(lhs: Duration, rhs: Duration) -> Bool {
        return lhs.millis == rhs.millis
    }
    
    public static func <=(lhs: Duration, rhs: Duration) -> Bool {
        return lhs.millis <= rhs.millis
    }
    
    public static func <(lhs: Duration, rhs: Duration) -> Bool {
        return lhs.millis < rhs.millis
    }
    
    public static func >(lhs: Duration, rhs: Duration) -> Bool {
        return lhs.millis > rhs.millis
    }
    
    public static func >=(lhs: Duration, rhs: Duration) -> Bool {
        return lhs.millis >= rhs.millis
    }
    
    public static func -(lhs: Duration, rhs: Duration) ->  Duration {
        return Duration(millis: lhs.millis - rhs.millis)
    }

}

extension Int {
    var millis: Duration { get { return Duration(millis: Int64(self)) } }
    var seconds: Duration { get { return Duration(seconds: Int64(self)) } }
    var minutes: Duration { get { return Duration(seconds: Int64(self * 60)) } }
    var hours: Duration { get { return Duration(seconds: Int64(self * 60 * 60)) } }
}

extension UInt {
    var millis: Duration { get { return Duration(ms: self) } }
    var seconds: Duration { get { return Duration(ms: self * 1000) } }
}

extension Float64 {
    var millis: Duration? { get { return Duration(millis: Int64(self)) } }
    var seconds: Duration? { get { return Duration(millis: Int64(self * 1000)) } }
}

extension Float {
    var millis: Duration? { get { return Duration(millis: Int64(self)) } }
    var seconds: Duration? { get { return Duration(millis: Int64(self * 1000)) } }
}
