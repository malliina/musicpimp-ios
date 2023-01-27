import Foundation

open class Throttler {
    let interval: Duration
    
    fileprivate var lastRun: Duration? = nil
    
    init(interval: Duration) {
        self.interval = interval
    }
    
    func throttled<T>(_ task: () -> T) -> T? {
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
