//
//  Downloader.swift
//  MusicPimp
//
//  Created by Michael Skogberg on 21/05/15.
//  Copyright (c) 2015 Skogberg Labs. All rights reserved.
//

import Foundation
class Downloader {
    static let musicDownloader = Downloader(basePath: LocalLibrary.sharedInstance.musicRootPath)
    let fileManager = NSFileManager.defaultManager()
    let documentsPath = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)[0] as! String
    
    let basePath: String
    init(basePath: String) {
        self.basePath = basePath
    }
    func download(url: NSURL, relativePath: String) {
        download(url, relativePath: relativePath, onError: { Log.info($0) })
    }
    func download(url: NSURL, relativePath: String, onError: ErrorMessage -> Void) {
        let destPath = self.basePath + "/" + relativePath.stringByReplacingOccurrencesOfString("\\", withString: "/")
        if !Files.exists(destPath) {
            Log.info("Downloading \(url) to \(relativePath)")
            let request = NSURLRequest(URL: url)
            NSURLConnection.sendAsynchronousRequest(request, queue: NSOperationQueue.currentQueue()) { (response, data, err) -> Void in
                if(err != nil) {
                    onError(ErrorMessage(message: "Error \(err)"))
                } else if(data != nil) {
                    let dir = destPath.stringByDeletingLastPathComponent
                    let dirSuccess = self.fileManager.createDirectoryAtPath(dir, withIntermediateDirectories: true, attributes: nil, error: nil)
                    if(dirSuccess) {
                        let fileSuccess = data.writeToFile(destPath, atomically: false)
                        if(fileSuccess) {
                            Log.info("Downloaded \(relativePath)")
                        } else {
                            onError(ErrorMessage(message: "Unable to write \(destPath)"))
                        }
                    } else {
                        onError(ErrorMessage(message: "Unable to ensure directory exists: \(dir)"))
                    }
                }
            }
        } else {
            Log.info("Already exists, not downloading \(relativePath)")
        }
    }
}
