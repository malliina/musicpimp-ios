//
//  DownloadUpdater.swift
//  MusicPimp
//
//  Created by Michael Skogberg on 28/10/2016.
//  Copyright © 2016 Skogberg Labs. All rights reserved.
//

import Foundation
import RxSwift

class DownloadUpdater {
    static let instance = DownloadUpdater(downloader: BackgroundDownloader.musicDownloader)
    let log = LoggerFactory.shared.network(DownloadUpdater.self)
    
    let progressSubject = PublishSubject<TrackProgress>()
    var progress: Observable<TrackProgress> { return progressSubject }
    var slowProgress: Observable<[TrackProgress]> { return progress.buffer(timeSpan: 1, count: 100, scheduler: ConcurrentDispatchQueueScheduler(qos: .background)) }
    
    fileprivate var downloadState: [RelativePath: TrackProgress] = [:]
    
    fileprivate var lastDownloadUpdate: DispatchTime? = nil
    let fps: UInt64 = 1

    let downloader: BackgroundDownloader
//    let innerDisposable: Disposable
    let bag = DisposeBag()
    
    var isEmpty: Bool { get { return downloadState.isEmpty } }
    
    init(downloader: BackgroundDownloader) {
        self.downloader = downloader
        downloader.events.subscribe(onNext: { (update) in
            self.onDownloadProgressUpdate(update)
        }).disposed(by: bag)
    }
    
    func progressFor(track: Track) -> TrackProgress? {
        return downloadState[track.path]
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
    
    private func onDownloadProgressUpdate(_ dpu: DownloadProgressUpdate) {
        // TODO use Rx to throttle this instead
        let path = dpu.relativePath
        if let trackProgress = downloadState[path] {
            let track = trackProgress.track
            let newProgress = TrackProgress(track: track, dpu: dpu)
            let isDownloadComplete = newProgress.isCompleted
            if isDownloadComplete {
                downloadState.removeValue(forKey: path)
                progressSubject.onNext(newProgress)
            } else {
                downloadState[path] = newProgress
//                progressSubject.onNext(newProgress)
                let now = DispatchTime.now()
                let shouldUpdate = enoughTimePassed(now: now)
                if shouldUpdate {
                    lastDownloadUpdate = now
                    progressSubject.onNext(newProgress)
                }
            }
        }
    }
    
    private func enoughTimePassed(now: DispatchTime) -> Bool {
        return DownloadUpdater.enoughTimePassed(now: now, last: lastDownloadUpdate, fps: fps)
    }
    
    static func enoughTimePassed(now: DispatchTime, last: DispatchTime?, fps: UInt64) -> Bool {
        if let last = last {
            let durationNanos = now.uptimeNanoseconds - last.uptimeNanoseconds
            return durationNanos / 1000000 > (1000 / fps)
        } else {
            return true
        }
    }
}
