import Foundation

protocol Volume {
  var value: UInt { get }
}
func volume(_ value: UInt) -> Volume? {
  class Vol: Volume {
    let value: UInt
    init(value: UInt) {
      self.value = value
    }
  }
  if value >= 0 && value <= 100 {
    return Vol(value: value)
  }
  return nil
}
