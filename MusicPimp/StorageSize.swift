import Foundation

struct StorageSize: CustomStringConvertible, Comparable, LargeIntCodable, Identifiable, Hashable {
  static let Zero = StorageSize(bytes: 0)
  static let k: Int = 1024
  static let k64 = Int64(StorageSize.k)

  let bytes: Int64
  var value: Int64 { bytes }

  init(bytes: Int64) {
    self.bytes = bytes
  }

  init(value: Int64) {
    self.init(bytes: value)
  }

  init(kilos: Int) {
    self.init(bytes: Int64(kilos) * StorageSize.k64)
  }

  init(megs: Int) {
    self.init(bytes: Int64(megs) * StorageSize.k64 * StorageSize.k64)
  }

  init(gigs: Int) {
    self.init(bytes: Int64(gigs) * StorageSize.k64 * StorageSize.k64 * StorageSize.k64)
  }

  var id: String { "\(bytes)" }
  var toBytes: Int64 { bytes }
  var toKilos: Int64 { toBytes / StorageSize.k64 }
  var toMegs: Int64 { toKilos / StorageSize.k64 }
  var toGigs: Int64 { toMegs / StorageSize.k64 }
  var toTeras: Int64 { toGigs / StorageSize.k64 }

  var description: String { shortDescription }

  var longDescription: String {
    describe(
      "bytes", kilos: "kilobytes", megas: "megabytes", gigas: "gigabytes", teras: "terabytes")
  }

  var shortDescription: String {
    describe("B", kilos: "KB", megas: "MB", gigas: "GB", teras: "TB")
  }

  fileprivate func describe(
    _ bytes: String, kilos: String, megas: String, gigas: String, teras: String
  ) -> String {
    return if toTeras >= 10 {
      "\(toTeras) \(teras)"
    } else if toGigs >= 10 {
      "\(toGigs) \(gigas)"
    } else if toMegs >= 10 {
      "\(toMegs) \(megas)"
    } else if toKilos >= 10 {
      "\(toKilos) \(kilos)"
    } else {
      "\(toBytes) \(bytes)"
    }
  }

  static func fromBytes(_ bytes: Int64) -> StorageSize? {
    bytes >= 0 ? StorageSize(bytes: Int64(bytes)) : nil
  }

  static func fromBytes(_ bytes: Int) -> StorageSize? {
    bytes >= 0 ? StorageSize(bytes: Int64(bytes)) : nil
  }

  static func fromKilos(_ kilos: Int) -> StorageSize? {
    kilos >= 0 ? StorageSize(kilos: Int(kilos)) : nil
  }

  static func fromMegs(_ megs: Int) -> StorageSize? {
    megs >= 0 ? StorageSize(megs: Int(megs)) : nil
  }

  static func fromGigas(_ gigs: Int) -> StorageSize? {
    gigs >= 0 ? StorageSize(gigs: Int(gigs)) : nil
  }

  public static func == (lhs: StorageSize, rhs: StorageSize) -> Bool {
    lhs.bytes == rhs.bytes
  }

  public static func <= (lhs: StorageSize, rhs: StorageSize) -> Bool {
    lhs.bytes <= rhs.bytes
  }

  public static func < (lhs: StorageSize, rhs: StorageSize) -> Bool {
    lhs.bytes < rhs.bytes
  }

  public static func > (lhs: StorageSize, rhs: StorageSize) -> Bool {
    lhs.bytes > rhs.bytes
  }

  public static func >= (lhs: StorageSize, rhs: StorageSize) -> Bool {
    lhs.bytes >= rhs.bytes
  }

  public static func + (lhs: StorageSize, rhs: StorageSize) -> StorageSize {
    StorageSize(bytes: lhs.bytes + rhs.bytes)
  }

  public static func - (lhs: StorageSize, rhs: StorageSize) -> StorageSize {
    StorageSize(bytes: lhs.bytes - rhs.bytes)
  }
}

extension Int {
  var bytes: StorageSize? { StorageSize.fromBytes(self) }
  var kilos: StorageSize? { StorageSize.fromKilos(self) }
  var megs: StorageSize? { StorageSize.fromMegs(self) }
}
extension UInt64 {
  var bytes: StorageSize { StorageSize(bytes: Int64(self)) }
  var kilos: StorageSize { StorageSize(bytes: Int64(Int64(self) * StorageSize.k64)) }
  var megs: StorageSize {
    StorageSize(bytes: Int64(Int64(self) * StorageSize.k64 * StorageSize.k64))
  }
}
