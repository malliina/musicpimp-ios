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
        let days = a.when.days.map { $0.rawValue }
        return [
            JsonKeys.ID: a.id?.id ?? NSNull(),
            JsonKeys.JOB: [JsonKeys.TRACK: a.track.id],
            JsonKeys.WHEN: [JsonKeys.Hour: when.hour, JsonKeys.Minute: when.minute, JsonKeys.Days: days ],
            JsonKeys.Enabled: a.enabled
        ]
    }
}

class AlarmTime {
    let hour: Int
    let minute: Int
    let days: [Day]
    
    init(hour: Int, minute: Int, days: [Day]) {
        self.hour = hour
        self.minute = minute
        self.days = days
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
