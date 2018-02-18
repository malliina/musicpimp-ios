//
//  Downloader.swift
//  MusicPimp
//
//  Created by Michael Skogberg on 21/05/15.
//  Copyright (c) 2015 Skogberg Labs. All rights reserved.
//

import Foundation

class Downloader {
    let log = LoggerFactory.network("Downloader")

    typealias RelativePath = String
    
    let fileManager = FileManager.default
    let documentsPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0] 
    let basePath: String
    
    init(basePath: String) {
        self.basePath = basePath
    }
    
    func download(_ url: URL, relativePath: RelativePath, replace: Bool = false) {
        download(
            url,
            relativePath: relativePath,
            replace: replace,
            onError: { (err: PimpError) -> Void in
                self.log.error(err.message)
            },
            onSuccess: { (destPath: String) -> Void in
            }
        )
    }
    
    func download(_ url: URL, relativePath: RelativePath, replace: Bool = false, onError: @escaping (PimpError) -> Void, onSuccess: @escaping (String) -> Void) {
        let destPath = pathTo(relativePath)
        if replace || !Files.exists(destPath) {
            log.info("Downloading \(url)")
            let request = URLRequest(url: url)
            let session = URLSession.shared
            session.dataTask(with: request) { (data, response, err) in
                if let err = err {
                    onError(self.simpleError("Error \(err)"))
                } else {
                    if let response = response as? HTTPURLResponse {
                        if response.isSuccess {
                            if let data = data {
                                let dir = destPath.stringByDeletingLastPathComponent()
                                let dirSuccess: Bool
                                do {
                                    try self.fileManager.createDirectory(atPath: dir, withIntermediateDirectories: true, attributes: nil)
                                    dirSuccess = true
                                } catch _ {
                                    dirSuccess = false
                                }
                                if dirSuccess {
                                    let fileSuccess = (try? data.write(to: URL(fileURLWithPath: destPath), options: [.atomic])) != nil
                                    if fileSuccess {
                                        //let size = Files.sharedInstance.fileSize(destPath) crashes
                                        self.log.info("Downloaded \(destPath)")
                                        onSuccess(destPath)
                                    } else {
                                        onError(self.simpleError("Unable to write \(destPath)"))
                                    }
                                } else {
                                    onError(self.simpleError("Unable to create directory: \(dir)"))
                                }
                                
                            }
                        } else {
                            onError(.responseFailure(ResponseDetails(resource: "\(url)", code: response.statusCode, message: nil)))
                        }
                    }
                }
            }
        } else {
            onSuccess(destPath)
            log.info("Already exists, not downloading \(relativePath)")
        }
    }
    
    func prepareDestination(_ relativePath: RelativePath) -> String? {
        let destPath = pathTo(relativePath)
        let dir = destPath.stringByDeletingLastPathComponent()
        let dirSuccess: Bool
        do {
            try self.fileManager.createDirectory(atPath: dir, withIntermediateDirectories: true, attributes: nil)
            dirSuccess = true
        } catch _ {
            dirSuccess = false
        }
        return dirSuccess ? destPath : nil
    }
    
    func pathTo(_ relativePath: RelativePath) -> String {
        return self.basePath + "/" + relativePath.replacingOccurrences(of: "\\", with: "/")
    }
    
    func simpleError(_ message: String) -> PimpError {
        return PimpError.simpleError(ErrorMessage(message: message))
    }
}
