//
//  Limiter.swift
//  MusicPimp
//
//  Created by Michael Skogberg on 09/01/16.
//  Copyright © 2016 Skogberg Labs. All rights reserved.
//

import Foundation

class Limiter: CustomStringConvertible {
    static let sharedInstance = Limiter(welcomeLimit: 10, limit: 4, duration: 24.hours)
    
    let welcomeLimit: Int
    let limit: Int
    let duration: Duration
    private let maxHistory: Int
    
    private var runs: [NSDate] = []
    
    var history: [NSDate] { return runs }
    
    init(welcomeLimit: Int, limit: Int, duration: Duration) {
        self.welcomeLimit = welcomeLimit
        self.limit = limit
        self.duration = duration
        self.maxHistory = max(welcomeLimit * 2, limit * 3)
        runs = PimpSettings.sharedInstance.trackHistory
    }
    
    func increment() {
        let now = NSDate()
        runs.insert(now, atIndex: 0)
        runs = runs.take(maxHistory)
    }
    
    func isWithinLimit() -> Bool {
        let now = NSDate()
        let runsWithinDuration = runs.howMany { date in
            self.diff(now, since: date) < self.duration
        }
        Log.info("\(runsWithinDuration) runs within \(self.duration)")
        return PimpSettings.sharedInstance.isUserPremium || runs.count < welcomeLimit || runsWithinDuration < limit
//        return runs.count < welcomeLimit || runsWithinDuration < limit
    }
    
    func diff(date: NSDate, since: NSDate) -> Duration {
        let d: Double = date.timeIntervalSinceDate(since)
        return d.seconds ?? Duration.Zero
    }
    
    var description: String { get { return "\(limit) tracks every \(duration) with \(welcomeLimit) welcome tracks" } }
}
