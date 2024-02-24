import Foundation

protocol SecondsCodable: Codable {
  init(seconds: Int64)
  var seconds: Int64 { get }
}

extension SecondsCodable {
  public init(from decoder: Decoder) throws {
    let container = try decoder.singleValueContainer()
    let raw = try container.decode(Int64.self)
    self.init(seconds: raw)
  }

  public func encode(to encoder: Encoder) throws {
    var container = encoder.singleValueContainer()
    try container.encode(seconds)
  }
}

struct Duration: CustomStringConvertible, Comparable, SecondsCodable {
  static let Zero = Duration(millis: 0)
  let millis: Int64
  var secondsFloat: Float { Float(seconds) }
  var seconds: Int64 { self.millis / 1000 }
  var minutes: Int64 { self.millis / 60000 }
  var hours: Int64 { self.millis / 3_600_000 }

  init(millis: Int64) {
    self.millis = millis
  }

  init(ms: UInt) {
    self.init(millis: Int64(ms))
  }

  init(seconds: Int64) {
    self.init(millis: seconds * 1000)
  }

  init(secs: UInt) {
    self.init(millis: Int64(secs * 1000))
  }

  init(minutes: UInt) {
    self.init(secs: minutes * 60)
  }

  init(hours: UInt) {
    self.init(minutes: hours * 60)
  }

  static func now() -> Duration {
    // can this fail?
    return Date().timeIntervalSince1970.seconds!
  }

  fileprivate func toReadable(_ duration: Duration) -> String {
    let hours = countHours(duration)
    let hs = padded(hours)
    let mins = padded(countMinutes(duration))
    let secs = padded(countSeconds(duration))
    if hours > 0 {
      return "\(hs):\(mins):\(secs)"
    } else {
      return "\(mins):\(secs)"
    }
  }

  fileprivate func padded(_ time: Int64) -> String {
    time < 10 ? "0\(time)" : "\(time)"
  }

  fileprivate func countSeconds(_ time: Duration) -> Int64 {
    time.seconds % 60
  }

  fileprivate func countMinutes(_ time: Duration) -> Int64 {
    time.minutes % 60
  }

  fileprivate func countHours(_ time: Duration) -> Int64 {
    time.seconds / 3600
  }

  var description: String { toReadable(self) }

  public static func == (lhs: Duration, rhs: Duration) -> Bool {
    lhs.millis == rhs.millis
  }

  public static func <= (lhs: Duration, rhs: Duration) -> Bool {
    lhs.millis <= rhs.millis
  }

  public static func < (lhs: Duration, rhs: Duration) -> Bool {
    lhs.millis < rhs.millis
  }

  public static func > (lhs: Duration, rhs: Duration) -> Bool {
    lhs.millis > rhs.millis
  }

  public static func >= (lhs: Duration, rhs: Duration) -> Bool {
    lhs.millis >= rhs.millis
  }

  public static func - (lhs: Duration, rhs: Duration) -> Duration {
    Duration(millis: lhs.millis - rhs.millis)
  }

}

extension Int {
  var millis: Duration { Duration(millis: Int64(self)) }
  var seconds: Duration { Duration(seconds: Int64(self)) }
  var minutes: Duration { Duration(seconds: Int64(self * 60)) }
  var hours: Duration { Duration(seconds: Int64(self * 60 * 60)) }
}

extension UInt {
  var millis: Duration { Duration(ms: self) }
  var seconds: Duration { Duration(ms: self * 1000) }
}

extension Float64 {
  var millis: Duration? { Duration(millis: Int64(self)) }
  var seconds: Duration? { Duration(millis: Int64(self * 1000)) }
}

extension Float {
  var millis: Duration? { Duration(millis: Int64(self)) }
  var seconds: Duration? { Duration(millis: Int64(self * 1000)) }
}
