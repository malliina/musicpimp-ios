import Foundation
import RxSwift

/// Downloads upcoming tracks in advance whenever the local track changes
class PlaylistPrefetcher {
  static let shared = PlaylistPrefetcher()

  let log = LoggerFactory.shared.network(PlaylistPrefetcher.self)
  let settings = PimpSettings.sharedInstance
  let downloader = DownloadUpdater.instance
  //    let playlist = LocalPlayer.sharedInstance.playlist
  let playlist = LocalPlaylist.sharedInstance
  let library = LocalLibrary.sharedInstance
  var disposable: Disposable? = nil
  let bag = DisposeBag()

  init() {
    playlist.indexEvent.subscribe(
      onNext: { (index) in
        self.onIndex(newIndex: index)
      }, onError: nil
    ).disposed(by: bag)
  }

  func onIndex(newIndex: Int?) {
    guard let idx = newIndex else { return }
    if settings.cacheEnabled {
      let _ = downloadIfNecessary(idx: idx + 1)
      let _ = downloadIfNecessary(idx: idx + 2)
    }
  }

  func downloadIfNecessary(idx: Int) -> ErrorMessage? {
    let ts = playlist.tracks()
    if idx >= ts.count { return nil }
    let track = ts[idx]
    if library.contains(track) { return nil }
    return downloader.downloadIfNecessary(track: track, authValue: library.authValue)
  }
}
