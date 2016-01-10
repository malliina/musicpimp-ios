//
//  Duration.swift
//  MusicPimp
//
//  Created by Michael Skogberg on 27/06/15.
//  Copyright (c) 2015 Skogberg Labs. All rights reserved.
//

import Foundation


public class Duration: CustomStringConvertible, Comparable {
    static let Zero = Duration(millis: 0)
    let millis: Int64
    var secondsFloat: Float { get { return Float(seconds) } }
    var seconds: Int64 { get { return self.millis / 1000 } }
    var minutes: Int64 { get { return self.millis / 60000 } }
    var hours: Int64 { get { return self.millis / 3600000 } }
    
    init(millis: Int64) {
        self.millis = millis
    }
    
    convenience init(ms: UInt) {
        self.init(millis: Int64(ms))
    }
    
    convenience init(seconds: Int)  {
        self.init(millis: Int64(seconds * 1000))
    }
    
    convenience init(secs: UInt)  {
        self.init(millis: Int64(secs * 1000))
    }
    
    convenience init(minutes: UInt) {
        self.init(secs: minutes * 60)
    }
    
    convenience init(hours: UInt) {
        self.init(minutes: hours * 60)
    }
    
    static func now() -> Duration {
        // can this fail?
        return NSDate().timeIntervalSince1970.seconds!
    }
    
    private func toReadable(duration: Duration) -> String {
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
    
    private func padded(time: Int64) -> String {
        return time < 10 ? "0\(time)" : "\(time)"
    }
    
    private func countSeconds(time: Duration) -> Int64 {
        return time.seconds % 60
    }
    
    private func countMinutes(time: Duration) -> Int64 {
        return time.minutes % 60
    }
    
    private func countHours(time: Duration) -> Int64 {
        return time.seconds / 3600
    }
    
    public var description: String { get { return toReadable(self) } }
}

public func ==(lhs: Duration, rhs: Duration) -> Bool {
    return lhs.millis == rhs.millis
}

public func <=(lhs: Duration, rhs: Duration) -> Bool {
    return lhs.millis <= rhs.millis
}

public func <(lhs: Duration, rhs: Duration) -> Bool {
    return lhs.millis < rhs.millis
}

public func >(lhs: Duration, rhs: Duration) -> Bool {
    return lhs.millis > rhs.millis
}

public func >=(lhs: Duration, rhs: Duration) -> Bool {
    return lhs.millis >= rhs.millis
}

func -(lhs: Duration, rhs: Duration) ->  Duration {
    return Duration(millis: lhs.millis - rhs.millis)
}

public extension Int {
    var millis: Duration { get { return Duration(millis: Int64(self)) } }
    var seconds: Duration { get { return Duration(seconds: self) } }
    var minutes: Duration { get { return Duration(seconds: self * 60) } }
    var hours: Duration { get { return Duration(seconds: self * 60 * 60) } }
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
