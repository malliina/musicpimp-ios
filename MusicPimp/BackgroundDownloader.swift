//
//  Downloader.swift
//  MusicPimp
//
//  Created by Michael Skogberg on 21/05/15.
//  Copyright (c) 2015 Skogberg Labs. All rights reserved.
//

import Foundation

typealias SessionID = String
public typealias RelativePath = String
public typealias DestinationURL = NSURL

class DownloadProgressUpdate {
    let info: DownloadInfo
    let writtenDelta: StorageSize
    let written: StorageSize
    let totalExpected: StorageSize?
    
    var relativePath: String { return info.relativePath }
    var destinationURL: NSURL { return info.destinationURL }
    
    init(info: DownloadInfo, writtenDelta: StorageSize, written: StorageSize, totalExpected: StorageSize?) {
        self.info = info
        self.writtenDelta = writtenDelta
        self.written = written
        self.totalExpected = totalExpected
    }
    
    func copy(newTotalExpected: StorageSize) -> DownloadProgressUpdate {
        return DownloadProgressUpdate(info: info, writtenDelta: writtenDelta, written: written, totalExpected: newTotalExpected)
    }
}

public class DownloadInfo {
    public let relativePath: RelativePath
    public let destinationURL: DestinationURL
    
    public init(relativePath: RelativePath, destinationURL: DestinationURL) {
        self.relativePath = relativePath
        self.destinationURL = destinationURL
    }
}

class BackgroundDownloader: NSObject, NSURLSessionDownloadDelegate, NSURLSessionTaskDelegate, NSURLSessionDelegate {
    
    typealias TaskID = Int
    
    static let musicDownloader = BackgroundDownloader(basePath: LocalLibrary.sharedInstance.musicRootPath, sessionID: "org.musicpimp.downloads.tracks")
    
    let events = Event<DownloadProgressUpdate>()
    
    private let fileManager = NSFileManager.defaultManager()
    let basePath: String
    
    private let sessionID: SessionID
    private var tasks: [TaskID: DownloadInfo] = [:]
    let lockQueue: dispatch_queue_t
    
    lazy var session: NSURLSession = self.setupSession()
    
    init(basePath: String, sessionID: SessionID) {
        self.basePath = basePath
        self.sessionID = sessionID
        self.tasks = PimpSettings.sharedInstance.tasks(sessionID)
        self.lockQueue = dispatch_queue_create(sessionID, nil)
    }
    
    func setup() {
        let desc = session.sessionDescription ?? "session"
        info("Initialized \(desc)")
    }
    
    private func stringify(state: NSURLSessionTaskState) -> String {
        switch state {
        case .Completed: return "Completed"
        case .Running: return "Running"
        case .Canceling: return "Canceling"
        case .Suspended: return "Suspended"
        }
    }
    
    private func setupSession() -> NSURLSession {
        let conf = NSURLSessionConfiguration.backgroundSessionConfigurationWithIdentifier(sessionID)
        conf.sessionSendsLaunchEvents = true
        conf.discretionary = false
        let session = NSURLSession(configuration: conf, delegate: self, delegateQueue: nil)
        session.getTasksWithCompletionHandler { (datas, uploads, downloads) -> Void in
            // removes outdated tasks
            let taskIDs = downloads.map({ (t) -> String in
                let stateDescribed = self.stringify(t.state)
                return "\(t.taskIdentifier): \(stateDescribed)"
            })
            self.synchronized {
                let actualTasks = self.tasks.filterKeys({ (taskID, value) -> Bool in
                    downloads.exists({ (task) -> Bool in
                        return task.taskIdentifier == taskID
                    })
                })
                if !taskIDs.isEmpty {
                    self.info("Restoring \(actualTasks.count) tasks, system had tasks \(taskIDs)")
                }
                self.tasks = actualTasks
            }
        }
        return session
    }
    
    func synchronized(f: () -> Void) {
        dispatch_async(self.lockQueue) {
            f()
        }
    }
    
    func download(url: NSURL, relativePath: RelativePath) -> ErrorMessage? {
        info("Preparing download of \(relativePath)")
        if let destPath = prepareDestination(relativePath) {
            let destURL = NSURL(fileURLWithPath: destPath)
            let info = DownloadInfo(relativePath: relativePath, destinationURL: destURL)
            return download(url, info: info)
        } else {
            return ErrorMessage(message: "Unable to prepare destination URL \(relativePath)")
        }
    }
    
    func download(src: NSURL, info: DownloadInfo) -> ErrorMessage? {
        let request = NSURLRequest(URL: src)
        let task = session.downloadTaskWithRequest(request)
        saveTask(task.taskIdentifier, di: info)
        task.resume()
        return nil
    }
    
    func saveTask(taskID: Int, di: DownloadInfo) {
        synchronized {
            self.tasks[taskID] = di
            self.persistTasks()
        }
    }
    
    func removeTask(taskID: Int) {
        synchronized {
            self.tasks.removeValueForKey(taskID)
            self.persistTasks()
        }
    }
    
    func persistTasks() {
//        info("Saving \(tasks)")
//        PimpSettings.sharedInstance.saveTasks(self.sessionID, tasks: self.tasks)
    }
    
    func prepareDestination(relativePath: RelativePath) -> String? {
        let destPath = pathTo(relativePath)
        let dir = destPath.stringByDeletingLastPathComponent()
        let dirSuccess: Bool
        do {
            try self.fileManager.createDirectoryAtPath(dir, withIntermediateDirectories: true, attributes: nil)
            dirSuccess = true
        } catch _ {
            dirSuccess = false
        }
        return dirSuccess ? destPath : nil
    }
    
    func pathTo(relativePath: RelativePath) -> String {
        return self.basePath + "/" + relativePath.stringByReplacingOccurrencesOfString("\\", withString: "/")
    }
    
    func urlTo(relativePath: RelativePath) -> NSURL? {
        return NSURL(fileURLWithPath: pathTo(relativePath))
    }
    
    func simpleError(message: String) -> PimpError {
        return PimpError.SimpleError(ErrorMessage(message: message))
    }
    
    func URLSession(session: NSURLSession, downloadTask: NSURLSessionDownloadTask, didFinishDownloadingToURL location: NSURL) {
        let taskID = downloadTask.taskIdentifier
        if let downloadInfo = tasks[taskID] {
            let destURL = downloadInfo.destinationURL
            let copySuccess: Bool
            do {
                try fileManager.moveItemAtURL(location, toURL: destURL)
                copySuccess = true
            } catch _ {
                copySuccess = false
            }
            let relPath = downloadInfo.relativePath
            if copySuccess {
                info("Completed download of \(relPath)")
            } else {
                info("File copy of \(relPath) failed to \(destURL)")
            }
        }
    }
    
    func URLSession(session: NSURLSession, downloadTask: NSURLSessionDownloadTask, didResumeAtOffset fileOffset: Int64, expectedTotalBytes: Int64) {
        info("Resumed at \(fileOffset)")
    }
    
    func URLSession(session: NSURLSession, downloadTask: NSURLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        let taskID = downloadTask.taskIdentifier
        let taskOpt = tasks[taskID]
        if let info = taskOpt,
            writtenDelta = StorageSize.fromBytes(bytesWritten),
            written = StorageSize.fromBytes(totalBytesWritten) {
            let expectedSize = StorageSize.fromBytes(totalBytesExpectedToWrite)
            let update = DownloadProgressUpdate(info: info, writtenDelta: writtenDelta, written: written, totalExpected: expectedSize)
            events.raise(update)
        } else {
            if taskOpt == nil {
                info("Download task not found: \(taskID)")
            } else {
                info("Unable to parse bytes of download progress: \(bytesWritten), \(totalBytesWritten)")
            }
        }
    }
    
    func URLSession(session: NSURLSession, task: NSURLSessionTask, didCompleteWithError error: NSError?) {
        let taskID = task.taskIdentifier
        if let error = error {
            let desc = error.localizedDescription
            info("Download error for \(taskID): \(desc)")
        } else {
            info("Task \(taskID) complete.")
        }
        removeTask(taskID)
    }
    
    func URLSessionDidFinishEventsForBackgroundURLSession(session: NSURLSession) {
        let sid = session.configuration.identifier
        info("All complete for session \(sid)")
        if let sid = sid, app = UIApplication.sharedApplication().delegate as? AppDelegate,
            handler = app.downloadCompletionHandlers.removeValueForKey(sid) {
                handler()
        }
    }
    
    func info(s: String) {
        Log.info(s)
    }
}
