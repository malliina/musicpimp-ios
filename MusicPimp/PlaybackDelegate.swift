import Foundation

protocol PlaybackDelegate {
  func onPlayPause() async
  func onPrev() async
  func onNext() async
}
