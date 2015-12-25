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
}
