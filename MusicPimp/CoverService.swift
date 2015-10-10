//
//  CoverService.swift
//  MusicPimp
//
//  Created by Michael Skogberg on 28/06/15.
//  Copyright (c) 2015 Skogberg Labs. All rights reserved.
//

import Foundation
class CoverResult {
    let artist: String
    let album: String
    let coverPath: String?
    let image: UIImage?
    var imageOrDefault: UIImage? { return image ?? CoverService.defaultCover }
    
    init(artist: String, album: String, coverPath: String?) {
        self.artist = artist
        self.album = album
        self.coverPath = coverPath
        if let path = coverPath {
            image = UIImage(contentsOfFile: path)
        } else {
            image = nil
        }
    }
    
    static func noCover(artist: String, album: String) -> CoverResult {
        return CoverResult(artist: artist, album: album, coverPath: nil)
    }
}

protocol CoverServiceType {
    func cover(artist: String, album: String)
}

class CoverService {
    static let sharedInstance = CoverService()
    static let coversDir = Files.documentsPath.stringByAppendingString("/covers")
    static let defaultCover = UIImage(named: "guitar.png")
    let downloader = Downloader(basePath: coversDir)
    
    func cover(artist: String, album: String, f: CoverResult -> Void) {
        let url = coverURL(artist, album: album)
        let relativeCoverFilePath = "\(artist)-\(album).jpg"
        downloader.download(
            url,
            relativePath: relativeCoverFilePath,
            onError: { (err) -> () in f(CoverResult.noCover(artist, album: album)) },
            onSuccess: { (path) -> () in f(CoverResult(artist: artist, album: album, coverPath: path)) }
        )
    }
    
    private func onError(msg: PimpError) -> Void {
        Log.error(PimpError.stringify(msg))
    }
    
    private func coverURL(artist: String, album: String) -> NSURL {
        let artEnc = Util.urlEncode(artist)
        let albEnc = Util.urlEncode(album)
        return Util.url("https://api.musicpimp.org/covers?artist=\(artEnc)&album=\(albEnc)")
    }
}
