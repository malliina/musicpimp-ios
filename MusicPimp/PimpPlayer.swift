import Foundation

class PimpPlayer: PimpEndpoint, PlayerType, PlayerEventDelegate {
  var isLocal: Bool { false }

  @Published var muteEvent: Bool?

  var playlist: PlaylistType
  let socket: PimpSocket

  fileprivate var currentState = PlayerState.empty

  let id: String

  init(e: Endpoint) {
    id = e.id
    let client = PimpHttpClient(baseURL: e.httpBaseUrl, authValue: e.authHeader)
    self.socket = PimpSocket(
      baseURL: URL(string: Endpoints.WS_PLAYBACK, relativeTo: e.wsBaseUrl)!, authValue: e.authHeader
    )
    self.playlist = PimpPlaylist(socket: self.socket)
    super.init(endpoint: e, client: client)
  }

  func open() async -> URL {
    socket.delegate = self
    return await socket.open()
  }

  func close() {
    self.socket.close()
  }

  func current() -> PlayerState {
    currentState
  }

  func resetAndPlay(tracks: [Track]) async -> ErrorMessage? {
    await socket.send(PlayItems(tracks: tracks))
  }

  func play() async -> ErrorMessage? {
    await sendSimple(JsonKeys.RESUME)
  }

  func pause() async -> ErrorMessage? {
    await sendSimple(JsonKeys.STOP)
  }

  func seek(_ position: Duration) async -> ErrorMessage? {
    await sendValued(IntPayload(seek: position))
  }

  func next() async -> ErrorMessage? {
    await sendSimple(JsonKeys.NEXT)
  }

  func prev() async -> ErrorMessage? {
    await sendSimple(JsonKeys.PREV)
  }

  func skip(_ index: Int) async -> ErrorMessage? {
    await sendValued(IntPayload(skip: index))
  }

  func volume(_ newVolume: VolumeValue) async -> ErrorMessage? {
    await sendValued(IntPayload(volumeChanged: newVolume.volume))
  }

  func sendValued<T: Encodable>(_ t: T) async -> ErrorMessage? {
    await socket.send(t)
  }

  func sendSimple(_ cmd: String) async -> ErrorMessage? {
    await socket.send(SimpleCommand(cmd: cmd))
  }

  func onTimeUpdated(_ pos: Duration) {
    currentState.position = pos
    time = pos
  }

  func onTrackChanged(_ track: Track?) {
    currentState.track = track
    self.track = track
    if let _ = track {
      Limiter.sharedInstance.increment()
    }
  }

  func onMuteToggled(_ mute: Bool) {
    currentState.mute = mute
    muteEvent = mute
  }

  func onVolumeChanged(_ volume: VolumeValue) {
    currentState.volume = volume
    self.volume = volume
  }

  func onStateChanged(_ state: PlaybackState) {
    currentState.state = state
    self.state = state
  }

  func onIndexChanged(_ index: Int?) {
    currentState.playlistIndex = index
    playlist.indexEvent = index
  }

  func onPlaylistModified(_ tracks: [Track]) {
    currentState.playlist = tracks
    playlist.playlistEvent = Playlist(tracks: tracks, index: currentState.playlistIndex)
  }

  func onState(_ state: PlayerStateJson) {
    currentState = state.mutable()
    onPlaylistModified(state.playlist)
    onIndexChanged(state.index)
    onTrackChanged(state.track)
    onMuteToggled(state.mute)
    onVolumeChanged(state.volume)
    onTimeUpdated(state.position)
    onStateChanged(state.playbackState)
  }
}
