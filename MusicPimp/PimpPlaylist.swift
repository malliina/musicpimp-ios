import Foundation

class PimpPlaylist: BasePlaylist, PlaylistType {
  let ResetPlaylist = "reset_playlist"
  let socket: PimpSocket

  init(socket: PimpSocket) {
    self.socket = socket
  }

  func skip(_ index: Int) async -> ErrorMessage? {
    await socket.send(IntPayload(skip: index))
  }

  func add(_ track: Track) async -> ErrorMessage? {
    await socket.send(AddTrackPayload(cmd: JsonKeys.ADD, track: track.id))
  }

  func add(_ tracks: [Track]) async -> [ErrorMessage] {
    await tracks.traverse { track in
      await add(track)
    }.compactMap({ $0 })
  }

  func removeIndex(_ index: Int) async -> ErrorMessage? {
    await socket.send(IntPayload(removeAt: index))
  }

  func move(_ src: Int, dest: Int) async -> ErrorMessage? {
    await socket.send(MoveTrack(cmd: JsonKeys.Move, from: src, to: dest))
  }

  func reset(_ index: Int?, tracks: [Track]) async -> ErrorMessage? {
    await socket.send(
      ResetPlaylistPayload(cmd: ResetPlaylist, index: index ?? -1, tracks: tracks.map { $0.id }))
  }
}

extension Sequence {
  func traverse<T>(_ f: (Element) async -> T) async -> [T] {
    var values = [T]()
    for e in self {
      let t = await f(e)
      values.append(t)
    }
    return values
  }
}
