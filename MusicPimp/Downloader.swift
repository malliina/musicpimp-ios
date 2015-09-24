//
//  Downloader.swift
//  MusicPimp
//
//  Created by Michael Skogberg on 21/05/15.
//  Copyright (c) 2015 Skogberg Labs. All rights reserved.
//

import Foundation
class Downloader {

    typealias RelativePath = String
    
    let fileManager = NSFileManager.defaultManager()
    let documentsPath = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)[0] 
    let basePath: String
    
    init(basePath: String) {
        self.basePath = basePath
    }
    
    func download(url: NSURL, relativePath: RelativePath, replace: Bool = false) {
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
    
    func download(url: NSURL, relativePath: RelativePath, replace: Bool = false, onError: PimpError -> Void, onSuccess: String -> Void) {
        let destPath = pathTo(relativePath)
        if replace || !Files.exists(destPath) {
            Log.info("Downloading \(url)")
            let request = NSURLRequest(URL: url)
            NSURLConnection.sendAsynchronousRequest(request, queue: NSOperationQueue.currentQueue()!) { (response, data, err) -> Void in
                if(err != nil) {
                    onError(self.simpleError("Error \(err)"))
                } else {
                    if let response = response as? NSHTTPURLResponse {
                        if response.isSuccess {
                            if let data = data {
                                let dir = destPath.stringByDeletingLastPathComponent()
                                let dirSuccess: Bool
                                do {
                                    try self.fileManager.createDirectoryAtPath(dir, withIntermediateDirectories: true, attributes: nil)
                                    dirSuccess = true
                                } catch _ {
                                    dirSuccess = false
                                }
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
    
    func simpleError(message: String) -> PimpError {
        return PimpError.SimpleError(ErrorMessage(message: message))
    }
    
    func info(s: String) {
        Log.info(s)
    }

}
