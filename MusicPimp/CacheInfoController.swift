import Foundation

class CacheInfoController: BaseTableController {
  var currentLimitDescription: String {
    let gigs = settings.cacheLimit.toGigs
    return "\(gigs) GB"
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    Task {
      for await limit in settings.$cacheLimitChanged.nonNilValues() {
        onCacheLimitChanged(limit)
      }
    }
  }

  func onCacheLimitChanged(_ newSize: StorageSize) {

  }
}
