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
    func download(url: NSURL, relativePath: String, replace: Bool = false) {
        download(
            url,
            relativePath: relativePath,
            replace: replace,
            onError: { (err: PimpError) -> Void in
                let msg = PimpErrorUtil.stringify(err)
                Log.error(msg)
            },
            onSuccess: { (destPath: String) -> Void in
                
                
            }
        )
    }
    func download(url: NSURL, relativePath: String, replace: Bool = false, onError: PimpError -> Void, onSuccess: String -> Void) {
        let destPath = pathTo(relativePath)
        if replace || !Files.exists(destPath) {
            Log.info("Downloading \(url) to \(destPath)")
            let request = NSURLRequest(URL: url)
            NSURLConnection.sendAsynchronousRequest(request, queue: NSOperationQueue.currentQueue()) { (response, data, err) -> Void in
                if(err != nil) {
                    onError(self.simpleError("Error \(err)"))
                } else {
                    if let response = response as? NSHTTPURLResponse {
                        if response.isSuccess {
                            if(data != nil) {
                                let dir = destPath.stringByDeletingLastPathComponent
                                let dirSuccess = self.fileManager.createDirectoryAtPath(dir, withIntermediateDirectories: true, attributes: nil, error: nil)
                                if(dirSuccess) {
                                    let fileSuccess = data.writeToFile(destPath, atomically: true)
                                    if(fileSuccess) {
                                        //let size = Files.sharedInstance.fileSize(destPath) crashes
                                        Log.info("Downloaded \(destPath)")
                                        onSuccess(destPath)
                                    } else {
                                        onError(self.simpleError("Unable to write \(destPath)"))
                                    }
                                } else {
                                    onError(self.simpleError("Unable to create directory: \(dir)"))
                                }
                            }
                        } else {
                            onError(.ResponseFailure("\(url)", response.statusCode, nil))
                        }
                    }
                }
            }
        } else {
            onSuccess(destPath)
            Log.info("Already exists, not downloading \(relativePath)")
        }
    }
    func pathTo(relativePath: String) -> String {
        return self.basePath + "/" + relativePath.stringByReplacingOccurrencesOfString("\\", withString: "/")
    }
    func simpleError(message: String) -> PimpError {
        return PimpError.SimpleError(ErrorMessage(message: message))
    }
}
