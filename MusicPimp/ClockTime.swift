//
//  ClockTime.swift
//  MusicPimp
//
//  Created by Michael Skogberg on 25/12/15.
//  Copyright © 2015 Skogberg Labs. All rights reserved.
//

import Foundation

class ClockTime {
    let hour: Int
    let minute: Int
    
    init(hour: Int, minute: Int) {
        self.hour = hour
        self.minute = minute
    }
    
    convenience init(date: NSDate) {
        let calendar = NSCalendar.currentCalendar()
        let comp = calendar.components([.Hour, .Minute], fromDate: date)
        self.init(hour: comp.hour, minute: comp.minute)
    }
    
    func dateComponents(from: NSDate = NSDate()) -> NSDateComponents {
        let calendar = NSCalendar.currentCalendar()
        let components = calendar.components([.Year, .Month, .Day, .Hour, .Minute], fromDate: from)
        components.calendar = calendar // wtf
        components.hour = hour
        components.minute = minute
        return components
    }
    
    func formatted() -> String {
        if let date = dateComponents().date {
            let formatter = NSDateFormatter()
            formatter.dateStyle = .NoStyle
            formatter.timeStyle = .ShortStyle
            return formatter.stringFromDate(date)
        } else {
            return "an unknown time"
        }
    }
}
