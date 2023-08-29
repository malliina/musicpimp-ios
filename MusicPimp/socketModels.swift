import Foundation

struct KeyedEvent: Codable {
    let event: String
}

struct TimeUpdated: Codable {
    let position: Duration
}

struct TrackChanged: Codable {
    let track: Track
}

struct MuteToggled: Codable {
    let mute: Bool
}

struct VolumeChanged: Codable {
    let volume: Int
}

struct PlayStateChanged: Codable {
    let state: PlayStateJson
    
    var playbackState: PlaybackState { return PlaybackState.from(state: state) }
}

struct IndexChanged: Codable {
    let index: Int
    
    private enum CodingKeys : String, CodingKey {
        case index = "playlist_index"
    }
}

struct PlaylistModified: Codable {
    let playlist: [Track]
}
