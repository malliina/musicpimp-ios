import Foundation

class LocalPlaylist: BasePlaylist, PlaylistType {
  private let log = LoggerFactory.shared.pimp(LocalPlaylist.self)
  static let sharedInstance = LocalPlaylist()

  fileprivate var ts: [Track] = []
  fileprivate var index: Int? = nil

  static func newPlaylistIndex(_ current: Int, src: Int, dest: Int) -> Int {
    return if src == current {
      dest
    } else if src < current && dest >= current {
      current - 1
    } else if src > current && dest <= current {
      current + 1
    } else {
      current
    }
  }

  func current() -> Playlist {
    Playlist(tracks: ts, index: index)
  }

  func position() -> Int? {
    index
  }

  func currentTrack() -> Track? {
    if let pos = position() {
      return trackAt(pos)
    }
    return nil
  }

  func next() -> Track? {
    positionTransform({ ($0 ?? -1) + 1 })
  }

  func prev() -> Track? {
    positionTransform({ ($0 ?? 1) - 1 })
  }

  func skip(_ index: Int) -> Track? {
    positionTransform({ _ in index })
  }

  func tracks() -> [Track] {
    ts
  }

  func reset(_ track: Track) -> ErrorMessage? {
    reset([track])
  }

  func reset(_ index: Int?, tracks: [Track]) -> ErrorMessage? {
    ts = tracks
    self.index = index
    playlistUpdated()
    indexEvent = index
    onTracksAdded(tracks)
    return nil
  }

  func reset(_ tracks: [Track]) -> ErrorMessage? {
    reset(tracks.count > 0 ? 0 : nil, tracks: tracks)
  }

  func add(_ track: Track) -> ErrorMessage? {
    add([track]).headOption()
  }

  func add(_ tracks: [Track]) -> [ErrorMessage] {
    ts.append(contentsOf: tracks)
    playlistUpdated()
    onTracksAdded(tracks)
    return []
  }

  func move(_ src: Int, dest: Int) -> ErrorMessage? {
    if src != dest {
      //let newTracks = Arrays.move(src, destIndex: dest, xs: ts)
      ts = Arrays.move(src, destIndex: dest, xs: ts)
      if let index = index {
        self.index = LocalPlaylist.newPlaylistIndex(index, src: src, dest: dest)
      }
      playlistUpdated()
    }
    return nil
  }

  fileprivate func onTracksAdded(_ ts: [Track]) {
    for track in ts {
      trackAdded = track
    }
  }

  func removeIndex(_ index: Int) -> ErrorMessage? {
    ts.remove(at: index)
    if let position = position() {
      if position == index {
        self.index = nil
      } else if position > index {
        self.index = position - 1
      }
    }
    playlistUpdated()
    return nil
  }

  func playlistUpdated() {
    playlistEvent = Playlist(tracks: ts, index: index)
  }

  func positionTransform(_ f: (Int?) -> Int) -> Track? {
    let nextPos = f(index)
    if let track = trackAt(nextPos) {
      index = nextPos
      indexEvent = index
      playlistUpdated()
      return track
    } else {
      log.error("Invalid playlist position \(nextPos)")
      return nil
    }
  }

  func trackAt(_ pos: Int) -> Track? {
    if pos >= 0 && pos < ts.count {
      return ts[pos]
    }
    return nil
  }
}
