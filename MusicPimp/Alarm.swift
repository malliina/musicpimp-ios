//
//  Alarm.swift
//  MusicPimp
//
//  Created by Michael Skogberg on 16/11/15.
//  Copyright © 2015 Skogberg Labs. All rights reserved.
//

import Foundation

struct AlarmJobIdOnly: Codable {
    let track: TrackID
}

struct AlarmJob: Codable {
    let track: Track
}

struct AlarmJson<T: Codable>: Codable {
    let id: AlarmID?
    let job: T
    let when: AlarmTime
    let enabled: Bool
}

extension AlarmJson where T == AlarmJob {
    func asAlarm() -> Alarm { return Alarm(id: id, track: job.track, when: when, enabled: enabled) }
}

class Alarm {
    let id: AlarmID?
    let track: Track
    let when: AlarmTime
    let enabled: Bool
    
    init(id: AlarmID?, track: Track, when: AlarmTime, enabled: Bool) {
        self.id = id
        self.track = track
        self.when = when
        self.enabled = enabled
    }
    
    func asJson() -> AlarmJson<AlarmJobIdOnly> {
        return AlarmJson(id: id, job: AlarmJobIdOnly(track: track.id), when: when, enabled: enabled)
    }
}

class MutableAlarm {
    let id: AlarmID?
    var track: Track?
    var when: MutableAlarmTime
    var enabled: Bool
    
    convenience init() {
        self.init(id: nil, track: nil, when: MutableAlarmTime(), enabled: true)
    }
    
    convenience init(_ a: Alarm) {
        self.init(id: a.id, track: a.track, when: MutableAlarmTime(at: a.when), enabled: a.enabled)
    }
    
    init(id: AlarmID?, track: Track?, when: MutableAlarmTime, enabled: Bool) {
        self.id = id
        self.track = track
        self.when = when
        self.enabled = enabled
    }
    
    func toImmutable() -> Alarm? {
        if let track = self.track {
            return Alarm(id: id, track: track, when: when.toImmutable(), enabled: enabled)
        } else {
            return nil
        }
    }
}

struct AlarmTime: Codable {
    let hour, minute: Int
    let days: [Day]
    
    var time: ClockTime { return ClockTime(hour: hour, minute: minute) }
}

class MutableAlarmTime {
    var hour: Int
    var minute: Int
    var days: [Day]
    
    init(at: AlarmTime) {
        self.hour = at.hour
        self.minute = at.minute
        self.days = at.days
    }
    
    init() {
        self.hour = 8
        self.minute = 0
        self.days = [ Day.Mon, Day.Tue, Day.Wed, Day.Thu, Day.Fri ]
    }
    
    func toImmutable() -> AlarmTime {
        return AlarmTime(hour: hour, minute: minute, days: days)
    }
}

enum Day: String, Codable {
    case Mon = "mon"
    case Tue = "tue"
    case Wed = "wed"
    case Thu = "thu"
    case Fri = "fri"
    case Sat = "sat"
    case Sun = "sun"
    
    static func fromName(_ name: String) -> Day? {
        return Day(rawValue: name)
    }
    
    static func index(_ day: Day) -> Int {
        switch day {
        case .Mon: return 0
        case .Tue: return 1
        case .Wed: return 2
        case .Thu: return 3
        case .Fri: return 4
        case .Sat: return 5
        case .Sun: return 6        }
    }
    
    static func describeDays(_ days: Set<Day>) -> String {
        if days.isEmpty {
            return "Never"
        }
        if days.count == 7 {
            return "Every day"
        }
        if days == [Day.Sat, Day.Sun] {
            return "Weekends"
        }
        if days == [Day.Mon, Day.Tue, Day.Wed, Day.Thu, Day.Fri] {
            return "Weekdays"
        }
        return days.sorted { (f, s) -> Bool in
            return Day.index(f) < Day.index(s)
            }.mkString(" ")
    }

}
