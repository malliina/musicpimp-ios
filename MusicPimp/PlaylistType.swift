import Foundation
import Combine

protocol PlaylistType {
  var indexPublisher: Published<Int?>.Publisher { get }
  var indexEvent: Int? { get set }
  var playlistPublisher: Published<Playlist?>.Publisher { get }
  var playlistEvent: Playlist? { get set }
  var trackPublisher: Published<Track?>.Publisher { get }
  var trackAdded: Track? { get set }

  func add(_ track: Track) async -> ErrorMessage?

  func add(_ tracks: [Track]) async -> [ErrorMessage]

  func removeIndex(_ index: Int) async -> ErrorMessage?

  func move(_ src: Int, dest: Int) async -> ErrorMessage?

  func reset(_ index: Int?, tracks: [Track]) async -> ErrorMessage?
}

extension PlaylistType {
  var updates: AnyPublisher<Playlist?, Never> {
    playlistPublisher.eraseToAnyPublisher()
  }
}
