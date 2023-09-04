
import Foundation

class CacheInfoController: BaseTableController {
    var currentLimitDescription: String {
        get {
            let gigs = settings.cacheLimit.toGigs
            return "\(gigs) GB"
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        run(settings.cacheLimitChanged, onResult: self.onCacheLimitChanged)
    }
    
    func onCacheLimitChanged(_ newSize: StorageSize) {
        
    }
}
