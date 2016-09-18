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
    
    convenience init(date: Date) {
        let calendar = Calendar.current
        let comp = (calendar as NSCalendar).components([.hour, .minute], from: date)
        self.init(hour: comp.hour!, minute: comp.minute!)
    }
    
    func dateComponents(_ from: Date = Date()) -> DateComponents {
        let calendar = Calendar.current
        var components = (calendar as NSCalendar).components([.year, .month, .day, .hour, .minute], from: from)
        (components as NSDateComponents).calendar = calendar // wtf
        components.hour = hour
        components.minute = minute
        return components
    }
    
    func formatted() -> String {
        if let date = (dateComponents() as NSDateComponents).date {
            let formatter = DateFormatter()
            formatter.dateStyle = .none
            formatter.timeStyle = .short
            return formatter.string(from: date)
        } else {
            return "an unknown time"
        }
    }
}
