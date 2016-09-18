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
    
    static func noCover(_ artist: String, album: String) -> CoverResult {
        return CoverResult(artist: artist, album: album, coverPath: nil)
    }
}

protocol CoverServiceType {
    func cover(_ artist: String, album: String)
}

class CoverService {
    static let sharedInstance = CoverService()
    static let coversDir = Files.documentsPath + "/covers"
    static let defaultCover = UIImage(named: "pimp-512.png")
    let downloader = Downloader(basePath: coversDir)
    
    func cover(_ artist: String, album: String, f: @escaping (CoverResult) -> Void) {
        let url = coverURL(artist, album: album)
        let relativeCoverFilePath = "\(artist)-\(album).jpg"
        downloader.download(
            url,
            relativePath: relativeCoverFilePath,
            onError: { (err) -> () in f(CoverResult.noCover(artist, album: album)) },
            onSuccess: { (path) -> () in f(CoverResult(artist: artist, album: album, coverPath: path)) }
        )
    }
    
    fileprivate func onError(_ msg: PimpError) -> Void {
        Log.error(PimpError.stringify(msg))
    }
    
    fileprivate func coverURL(_ artist: String, album: String) -> URL {
        let artEnc = artist.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed) ?? artist
        let albEnc = album.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed) ?? album
        return Util.url("https://api.musicpimp.org/covers?artist=\(artEnc)&album=\(albEnc)")
    }
}
