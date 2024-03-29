import Combine
import Foundation

class Util {
  static let log = LoggerFactory.shared.base("Util", category: Util.self)

  fileprivate static var GlobalMainQueue: DispatchQueue {
    DispatchQueue.main
  }

  class func onUiThread(_ f: @escaping () -> Void) {
    DispatchQueue.main.async(execute: f)
  }

  class func onBackgroundThread(_ f: @escaping () -> Void) {
    DispatchQueue.global(qos: .background).async(execute: f)
  }

  class func hasTimePassed(time: Duration, now: DispatchTime, since: DispatchTime?) -> Bool {
    if let since = since {
      let elapsedMillis = (now.uptimeNanoseconds - since.uptimeNanoseconds) / 1_000_000
      return elapsedMillis > UInt64(time.millis)
    } else {
      return true
    }
  }

  class func urlDecodeWithPlus(_ s: String) -> String {
    let unplussed = s.replacingOccurrences(of: "+", with: " ")
    return unplussed.removingPercentEncoding ?? unplussed
  }

  class func urlEncodePathWithPlus(_ s: String) -> String {
    let plussed = s.replacingOccurrences(of: " ", with: "+")
    return urlEncodePath(plussed)
  }

  class func urlEncodeHost(_ s: String) -> String {
    encodeWith(s, cs: .urlHostAllowed)
  }

  class func urlEncodePath(_ s: String) -> String {
    encodeWith(s, cs: .urlPathAllowed)
  }

  class func urlEncodeQueryString(_ s: String) -> String {
    encodeWith(s, cs: .urlQueryAllowed)
  }

  fileprivate class func encodeWith(_ s: String, cs: CharacterSet) -> String {
    s.addingPercentEncoding(withAllowedCharacters: cs) ?? s
  }

  static func onError(_ error: Error) {
    log.error(message(error: error))
  }

  static func message(error: Error) -> String {
    guard let error = error as? PimpError else { return "Unknown error" }
    return PimpErrorUtil.stringifyDetailed(error)
  }

  // TODO source? SO?
  static func imageWithSize(image: UIImage, scaledToSize newSize: CGSize) -> UIImage {
    UIGraphicsBeginImageContextWithOptions(newSize, false, 0.0)
    image.draw(
      in: CGRect(
        origin: CGPoint(x: 0, y: 0), size: CGSize(width: newSize.width, height: newSize.height)))
    let newImage: UIImage = UIGraphicsGetImageFromCurrentImageContext()!
    UIGraphicsEndImageContext()
    return newImage
  }
}

extension UIImage {
  func withSize(scaledToSize: CGSize) -> UIImage {
    Util.imageWithSize(image: self, scaledToSize: scaledToSize)
  }
}

extension Data {
  // thanks Martin, http://codereview.stackexchange.com/a/86613
  func hexString() -> String {
    // "Array" of all bytes
    let bytes = UnsafeBufferPointer<UInt8>(
      start: (self as NSData).bytes.bindMemory(to: UInt8.self, capacity: self.count),
      count: self.count)
    // Array of hex strings, one for each byte
    let hexBytes = bytes.map { String(format: "%02hhx", $0) }
    // Concatenates all hex strings
    return hexBytes.joined(separator: "")
  }
}

extension Publisher where Self.Failure == Never {
  public func removeNils<T>() -> Publishers.CompactMap<Self, T> where Self.Output == T? {
    self.compactMap { out in
      out
    }
  }

  public func nonNilValues<T>() -> AsyncPublisher<Publishers.CompactMap<Self, T>>
  where Self.Output == T? {
    removeNils().values
  }
}
