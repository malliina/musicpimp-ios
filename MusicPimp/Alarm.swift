//
//  Alarm.swift
//  MusicPimp
//
//  Created by Michael Skogberg on 16/11/15.
//  Copyright © 2015 Skogberg Labs. All rights reserved.
//

import Foundation

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
    
    static func toJson(a: Alarm) -> [String: AnyObject] {
        let when = a.when
        let days = when.days.map { $0.rawValue }
        return [
            JsonKeys.ID: a.id?.id ?? NSNull(),
            JsonKeys.JOB: [ JsonKeys.TRACK: a.track.id ],
            JsonKeys.WHEN: [ JsonKeys.Hour: when.hour, JsonKeys.Minute: when.minute, JsonKeys.Days: days ],
            JsonKeys.Enabled: a.enabled
        ]
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
    
    convenience init(a: Alarm) {
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

class AlarmTime {
    let hour: Int
    let minute: Int
    let days: Set<Day>
    
    init(hour: Int, minute: Int, days: Set<Day>) {
        self.hour = hour
        self.minute = minute
        self.days = days
    }
}

class MutableAlarmTime {
    var hour: Int
    var minute: Int
    var days: Set<Day>
    
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

class AlarmJob {
    let track: TrackID
    
    init(track: TrackID) {
        self.track = track
    }
}

enum Day: String {
    case Mon = "mon"
    case Tue = "tue"
    case Wed = "wed"
    case Thu = "thu"
    case Fri = "fri"
    case Sat = "sat"
    case Sun = "sun"
    
    static func fromName(name: String) -> Day? {
        return Day(rawValue: name)
    }
    
    static func index(day: Day) -> Int {
        switch day {
        case .Mon: return 0
        case .Tue: return 1
        case .Wed: return 2
        case .Thu: return 3
        case .Fri: return 4
        case .Sat: return 5
        case .Sun: return 6        }
    }
}

class AlarmID {
    let id: String
    
    init(id: String) {
        self.id = id
    }
}

class TrackID {
    let id: String
    
    init(id: String) {
        self.id = id
    }
}
