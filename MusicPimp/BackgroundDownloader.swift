//
//  Downloader.swift
//  MusicPimp
//
//  Created by Michael Skogberg on 21/05/15.
//  Copyright (c) 2015 Skogberg Labs. All rights reserved.
//

import Foundation

typealias SessionID = String
typealias RelativePath = String
typealias DestinationURL = NSURL

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

class DownloadInfo {
    let relativePath: RelativePath
    let destinationURL: DestinationURL
    
    init(relativePath: RelativePath, destinationURL: DestinationURL) {
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
    private var session: NSURLSession? = nil
    private var tasks: [TaskID: DownloadInfo] = [:]
    
    init(basePath: String, sessionID: SessionID) {
        self.basePath = basePath
        self.sessionID = sessionID
    }
    
    // TODO do a lazy var instead
    func setupSession() {
        let conf = NSURLSessionConfiguration.backgroundSessionConfigurationWithIdentifier(sessionID)
        conf.sessionSendsLaunchEvents = true
        conf.discretionary = true
        self.session = NSURLSession(configuration: conf, delegate: self, delegateQueue: nil)
        info("Initialized music session \(sessionID)")
    }
    
    func download(url: NSURL, relativePath: RelativePath, replace: Bool = false) -> ErrorMessage? {
        info("Preparing download of \(relativePath)")
        if let destPath = prepareDestination(relativePath), destURL = NSURL(fileURLWithPath: destPath) {
            let info = DownloadInfo(relativePath: relativePath, destinationURL: destURL)
            return download(url, info: info)
        } else {
            return ErrorMessage(message: "Unable to prepare destination URL \(relativePath)")
        }
    }
    
    func download(src: NSURL, info: DownloadInfo) -> ErrorMessage? {
        let request = NSURLRequest(URL: src)
        if let task = session?.downloadTaskWithRequest(request) {
            tasks[task.taskIdentifier] = info
            task.resume()
            return nil
        } else {
            return ErrorMessage(message: "No session. Cannot download \(src).")
        }
    }
    
    func prepareDestination(relativePath: RelativePath) -> String? {
        let destPath = pathTo(relativePath)
        let dir = destPath.stringByDeletingLastPathComponent
        let dirSuccess = self.fileManager.createDirectoryAtPath(dir, withIntermediateDirectories: true, attributes: nil, error: nil)
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
        info("Finished downloading \(taskID) to \(location)")
        if let downloadInfo = tasks[taskID] {
            let destURL = downloadInfo.destinationURL
            let copySuccess = fileManager.copyItemAtURL(location, toURL: destURL, error: nil)
            if copySuccess {
                info("Downloaded file to \(destURL)")
            } else {
                info("File copy failed to \(destURL)")
            }
        }
    }
    
    func URLSession(session: NSURLSession, downloadTask: NSURLSessionDownloadTask, didResumeAtOffset fileOffset: Int64, expectedTotalBytes: Int64) {
        info("Resumed at \(fileOffset)")
    }
    
    func URLSession(session: NSURLSession, downloadTask: NSURLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        let taskID = downloadTask.taskIdentifier
        if let info = tasks[taskID], writtenDelta = StorageSize.fromBytes(bytesWritten), written = StorageSize.fromBytes(totalBytesWritten) {
            let expectedSize = StorageSize.fromBytes(totalBytesExpectedToWrite)
            let update = DownloadProgressUpdate(info: info, writtenDelta: writtenDelta, written: written, totalExpected: expectedSize)
            events.raise(update)
        } else {
            info("Unable to parse download progress update of task \(taskID)")
        }
        //info("Wrote: \(bytesWritten) of \(taskID), written: \(totalBytesWritten), expected total: \(totalBytesExpectedToWrite)")
    }
    
    func URLSession(session: NSURLSession, task: NSURLSessionTask, didCompleteWithError error: NSError?) {
        let taskID = task.taskIdentifier
        if let error = error {
            let desc = error.localizedDescription
            info("Download error for \(taskID): \(desc)")
        } else {
            info("Task \(taskID) complete.")
        }
        tasks.removeValueForKey(taskID)
    }
    
    func URLSessionDidFinishEventsForBackgroundURLSession(session: NSURLSession) {
        let sid = session.configuration.identifier
        info("All complete for session \(sid)")
        if let app = UIApplication.sharedApplication().delegate as? AppDelegate,
            handler = app.downloadCompletionHandlers.removeValueForKey(sid) {
                handler()
        }
    }
    
    func info(s: String) {
        Log.info(s)
    }
}
