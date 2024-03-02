import Foundation

protocol PlaylistType {
  var indexPublisher: Published<Int?>.Publisher { get }
  var indexEvent: Int? { get set }
  var playlistPublisher: Published<Playlist?>.Publisher { get }
  var playlistEvent: Playlist? { get set }
  var trackPublisher: Published<Track?>.Publisher { get }
  var trackAdded: Track? { get set }

  func add(_ track: Track) -> ErrorMessage?

  func add(_ tracks: [Track]) -> [ErrorMessage]

  func removeIndex(_ index: Int) -> ErrorMessage?

  func move(_ src: Int, dest: Int) -> ErrorMessage?

  func reset(_ index: Int?, tracks: [Track]) -> ErrorMessage?
}
