
import Foundation
import RxSwift

class CoverResult {
    static let log = LoggerFactory.shared.network(CoverService.self)
    let artist: String
    let album: String
    let coverPath: String?
    let image: UIImage?
    var imageOrDefault: UIImage? { image ?? CoverService.defaultCover }
    
    init(artist: String, album: String, coverPath: String?) {
        self.artist = artist
        self.album = album
        self.coverPath = coverPath
        if let path = coverPath {
            image = UIImage(contentsOfFile: path)
            if image == nil {
                CoverResult.log.info("Got path at \(path) but failed to construct image.")
            }
        } else {
            CoverResult.log.info("No path, no image.")
            image = nil
        }
    }
    
    static func noCover(_ artist: String, album: String) -> CoverResult {
        CoverResult(artist: artist, album: album, coverPath: nil)
    }
}

protocol CoverServiceType {
    func cover(_ artist: String, album: String)
}

class CoverService {
    let log = LoggerFactory.shared.network(CoverService.self)
    static let sharedInstance = CoverService()
    static let coversDir = Files.documentsPath + "/covers"
    static let defaultCover = UIImage(named: "pimp-512.png")
    
    let downloader = Downloader(basePath: coversDir)
    
    func cover(_ artist: String, album: String) -> Single<CoverResult> {
        if let url = coverURL(artist, album: album) {
            let relativeCoverFilePath = "\(artist)-\(album).jpg"
            return downloader.download(
                url,
                authValue: nil,
                relativePath: relativeCoverFilePath)
                .map { path in
//                    self.log.info("Got \(path)")
                    return CoverResult(artist: artist, album: album, coverPath: path) }
                .catch { err in 
                    self.log.info("Failed to download cover. \(err)")
                    return Single.just(CoverResult.noCover(artist, album: album)) }
        } else {
            return Single.just(CoverResult.noCover(artist, album: album))
        }
    }
    
    fileprivate func onError(_ msg: PimpError) -> Void {
        log.error(msg.message)
    }
    
    fileprivate func coverURL(_ artist: String, album: String) -> URL? {
        let artEnc = queryStringEncoded(s: artist)
        let albEnc = queryStringEncoded(s: album)
        return URL(string: "https://api.musicpimp.org/covers?artist=\(artEnc)&album=\(albEnc)")
    }
    
    func queryStringEncoded(s: String) -> String {
        s.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed) ?? s
    }
}
