//
//  Duration.swift
//  MusicPimp
//
//  Created by Michael Skogberg on 27/06/15.
//  Copyright (c) 2015 Skogberg Labs. All rights reserved.
//

import Foundation
class Duration: Printable, Comparable {
    static let Zero = Duration(millis: 0)
    let millis: UInt64
    var secondsFloat: Float { get { return Float(seconds) } }
    var seconds: UInt64 { get { return self.millis / 1000 } }
    var minutes: UInt64 { get { return self.millis / 60000 } }
    var hours: UInt64 { get { return self.millis / 3600000 } }
    
    init(millis: UInt64) {
        self.millis = millis
    }
    convenience init(ms: UInt) {
        self.init(millis: UInt64(ms))
    }
    convenience init(seconds: UInt)  {
        self.init(millis: UInt64(seconds * 1000))
    }
    convenience init(minutes: UInt) {
        self.init(seconds: minutes * 60)
    }
    convenience init(hours: UInt) {
        self.init(minutes: hours * 60)
    }
    static func fromMillis(millis: Int) -> Duration? {
        if(millis >= 0) {
            return Duration(millis: UInt64(millis))
        } else {
            return nil
        }
    }
    static func fromSeconds(seconds: Int) -> Duration? {
        return fromMillis(seconds * 1000)
    }
    
    private func toReadable(secs: UInt64) -> String {
        let hs = padded(countHours(secs))
        let mins = padded(countMinutes(secs))
        let secs = padded(countSeconds(secs))
        return "\(hs):\(mins):\(secs)"
    }
    private func padded(time: UInt64) -> String {
        return time < 10 ? "0\(time)" : "\(time)"
    }
    private func countSeconds(time: UInt64) -> UInt64 {
        return time % 60
    }
    private func countMinutes(time: UInt64) -> UInt64 {
        return time / 60
    }
    private func countHours(time: UInt64) -> UInt64 {
        return time / 3600
    }
    
    var description: String { get { return toReadable(seconds) } }
}
func ==(lhs: Duration, rhs: Duration) -> Bool {
    return lhs.millis == rhs.millis
}
func <=(lhs: Duration, rhs: Duration) -> Bool {
    return lhs.millis <= rhs.millis
}
func <(lhs: Duration, rhs: Duration) -> Bool {
    return lhs.millis < rhs.millis
}
func >(lhs: Duration, rhs: Duration) -> Bool {
    return lhs.millis > rhs.millis
}
func >=(lhs: Duration, rhs: Duration) -> Bool {
    return lhs.millis >= rhs.millis
}
extension Int {
    var millis: Duration? { get { return Duration.fromMillis(self) } }
    var seconds: Duration? { get { return Duration.fromSeconds(self) } }
}
extension UInt {
    var millis: Duration { get { return Duration(ms: self) } }
    var seconds: Duration { get { return Duration(seconds: self) } }
}
extension Float64 {
    var millis: Duration? { get { return Duration.fromMillis(Int(self)) } }
    var seconds: Duration? { get { return Duration.fromMillis(Int(self * 1000)) } }
}
extension Float {
    var millis: Duration? { get { return Duration.fromMillis(Int(self)) } }
    var seconds: Duration? { get { return Duration.fromMillis(Int(self * 1000)) } }
}