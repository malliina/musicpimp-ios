//
//  DownloadUpdater.swift
//  MusicPimp
//
//  Created by Michael Skogberg on 28/10/2016.
//  Copyright © 2016 Skogberg Labs. All rights reserved.
//

import Foundation

class DownloadUpdater {
    static let instance = DownloadUpdater(downloader: BackgroundDownloader.musicDownloader)
    
    let progress = Event<TrackProgress>()
    
    fileprivate var downloadState: [RelativePath: TrackProgress] = [:]
    
    fileprivate var lastDownloadUpdate: DispatchTime? = nil
    let fps: UInt64 = 30

    let downloader: BackgroundDownloader
//    let innerDisposable: Disposable
    
    var isEmpty: Bool { get { return downloadState.isEmpty } }
    
    init(downloader: BackgroundDownloader) {
        self.downloader = downloader
        let _ = downloader.events.addHandler(self) { (me) -> (DownloadProgressUpdate) -> () in
            me.onDownloadProgressUpdate
        }
    }
    
    func progressFor(track: Track) -> TrackProgress? {
        return downloadState[track.path]
    }
    
    func download(track: Track) -> ErrorMessage? {
        if let info = downloader.download(track.url, relativePath: track.path) {
            let initialProgress = TrackProgress.initial(track: track, info: info)
            downloadState[track.path] = initialProgress
            return nil
        } else {
            return ErrorMessage(message: "Unable to download \(track.id)")
        }
    }
    
    // call from viewWillAppear
    func listen(onProgress: @escaping (TrackProgress) -> Void) -> Disposable {
        return progress.addHandler(self) { (me) -> (TrackProgress) -> () in
            onProgress
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
                progress.raise(newProgress)
            } else {
                downloadState[path] = newProgress
                let now = DispatchTime.now()
                let shouldUpdate = enoughTimePassed(now: now)
                if shouldUpdate {
                    lastDownloadUpdate = now
                    progress.raise(newProgress)
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
