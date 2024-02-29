import Foundation
import RxSwift

// Intentionally does not implement PlaylistType because Swift sucks, but PlaylistType implementations
// can still extend this for convenience
class BasePlaylist {
  @Published var indexEvent: Int?
  var indexPublisher: Published<Int?>.Publisher { $indexEvent }
  @Published var playlistEvent: Playlist?
  var playlistPublisher: Published<Playlist?>.Publisher { $playlistEvent }
  @Published var trackAdded: Track?
  var trackPublisher: Published<Track?>.Publisher { $trackAdded }
}
