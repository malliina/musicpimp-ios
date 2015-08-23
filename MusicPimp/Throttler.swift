//
//  Runner.swift
//  MusicPimp
//
//  Created by Michael Skogberg on 14/08/15.
//  Copyright (c) 2015 Skogberg Labs. All rights reserved.
//

import Foundation

public class Throttler {
    let interval: Duration
    
    private var lastRun: Duration? = nil
    
    init(interval: Duration) {
        self.interval = interval
    }
    
    func throttled<T>(task: () -> T) -> T? {
        let now = Duration.now()
        var hasEnoughTimePassed = true
        if let lastRun = lastRun {
            let sinceLast = now - lastRun
            if sinceLast < interval {
                hasEnoughTimePassed = false
            }
        }
        if hasEnoughTimePassed {
            lastRun = now
            return task()
        } else {
            return nil
        }
    }
}