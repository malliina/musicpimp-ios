
import Foundation
import RxSwift
import RxCocoa

class Downloader {
    let log = LoggerFactory.shared.network(Downloader.self)

    typealias RelativePath = String
    
    let fileManager = FileManager.default
    let documentsPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0] 
    let basePath: String
    let session = URLSession.shared
    
    init(basePath: String) {
        self.basePath = basePath
    }
    
    func download(_ url: URL, authValue: String?, relativePath: RelativePath, replace: Bool = false) -> Single<String> {
        let destPath = pathTo(relativePath)
        let subject: PublishSubject<String> = PublishSubject()
        if replace || !Files.exists(destPath) {
            log.info("Downloading \(url)")
            var request = URLRequest(url: url)
            if let authValue = authValue {
                request.addValue(authValue, forHTTPHeaderField: "Authorization")
            }
            
            let task = session.dataTask(with: request) { (data, response, err) in
                if let err = err {
                    subject.onError(self.simpleError("Error \(err)"))
                } else {
                    guard let response = response as? HTTPURLResponse else {
                        subject.onError(self.simpleError("Unknown response."))
                        return
                    }
                    guard response.isSuccess else {
                        subject.onError(PimpError.responseFailure(ResponseDetails(resource: url, code: response.statusCode, message: nil)))
                        return
                    }
                    guard let data = data else {
                        subject.onError(self.simpleError("No data in response."))
                        return
                    }
                    let dir = destPath.stringByDeletingLastPathComponent()
                    guard (try? self.fileManager.createDirectory(atPath: dir, withIntermediateDirectories: true, attributes: nil)) != nil else {
                        subject.onError(self.simpleError("Unable to create directory: \(dir)"))
                        return
                    }
                    guard (try? data.write(to: URL(fileURLWithPath: destPath), options: [.atomic])) != nil else {
                        subject.onError(self.simpleError("Unable to write \(destPath)"))
                        return
                    }
                    //let size = Files.sharedInstance.fileSize(destPath) crashes
                    self.log.info("Downloaded \(destPath)")
                    subject.onNext(destPath)
                    subject.onCompleted()
                }
            }
            task.resume()
        } else {
            subject.onNext(destPath)
            subject.onCompleted()
            log.info("Already exists, not downloading \(relativePath)")
        }
        return subject.asSingle()
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
        return PimpError.simpleError(ErrorMessage(message))
    }
}
