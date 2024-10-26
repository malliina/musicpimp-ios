import Combine
import Foundation

protocol DownloaderLike: ObservableObject {
  var trackProgress: [TrackID: any ProgressLike] { get }
}

class DownloadUpdater: DownloaderLike {
  static let instance = DownloadUpdater(downloader: BackgroundDownloader.musicDownloader)
  let log = LoggerFactory.shared.network(DownloadUpdater.self)
  @Published var progress: [TrackID: TrackProgress] = [:]
  @Published var slowProgress: [TrackID: TrackProgress] = [:]
  var trackProgress: [TrackID : any ProgressLike] { slowProgress }
  private let q = DispatchQueue(label: "DownloadUpdater")

  fileprivate var downloadState: [RelativePath: TrackProgress] = [:]

  fileprivate var lastDownloadUpdate: DispatchTime? = nil
  let fps: UInt64 = 1

  let downloader: BackgroundDownloader

  var isEmpty: Bool { downloadState.isEmpty }
  
  init(downloader: BackgroundDownloader) {
    self.downloader = downloader
    Task {
      for await update in downloader.$events.nonNilValues() {
        await onDownloadProgressUpdate(update)
      }
    }
    Task {
      for await latest in $progress.throttle(for: 0.04, scheduler: q, latest: true).values {
        await update(slow: latest)
      }
    }
  }

  func progressFor(track: Track) -> TrackProgress? {
    downloadState[track.path]
  }

  func downloadIfNecessary(track: Track, authValue: String) -> ErrorMessage? {
    let alreadyDownloading = downloadState.contains { (path, _) -> Bool in
      path == track.path
    }
    if alreadyDownloading {
      log.info("Already downloading \(track.path), dropping additional download request.")
      return nil
    }
    return download(track: track, authValue: authValue)
  }

  func download(track: Track, authValue: String) -> ErrorMessage? {
    if let info = downloader.download(track.url, authValue: authValue, relativePath: track.path) {
      let initialProgress = TrackProgress.initial(track: track, info: info)
      downloadState[track.path] = initialProgress
      return nil
    } else {
      return ErrorMessage("Unable to download \(track.id)")
    }
  }

  private func onDownloadProgressUpdate(_ dpu: DownloadProgressUpdate) async {
    let path = dpu.relativePath
    if let trackProgress = downloadState[path] {
      let track = trackProgress.track
      let newProgress = TrackProgress(track: track, dpu: dpu)
      let isDownloadComplete = newProgress.isCompleted
      if isDownloadComplete {
        downloadState.removeValue(forKey: path)
      } else {
        downloadState[path] = newProgress
        let now = DispatchTime.now()
        let shouldUpdate = enoughTimePassed(now: now)
        if shouldUpdate {
          lastDownloadUpdate = now
        }
      }
      await update(trackProgress: newProgress)
    }
  }
  
  @MainActor func update(trackProgress: TrackProgress) {
    let id = trackProgress.track.id
    var updated = progress
    if trackProgress.isCompleted {
      updated.removeValue(forKey: id)
    } else {
      updated.updateValue(trackProgress, forKey: id)
    }
    progress = updated
  }
  
  @MainActor func update(slow: [TrackID: TrackProgress]) {
    slowProgress = slow
  }

  private func enoughTimePassed(now: DispatchTime) -> Bool {
    DownloadUpdater.enoughTimePassed(now: now, last: lastDownloadUpdate, fps: fps)
  }

  static func enoughTimePassed(now: DispatchTime, last: DispatchTime?, fps: UInt64) -> Bool {
    if let last = last {
      let durationNanos = now.uptimeNanoseconds - last.uptimeNanoseconds
      return durationNanos / 1_000_000 > (1000 / fps)
    } else {
      return true
    }
  }
}
