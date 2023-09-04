
import Foundation

protocol TopEntry {
    var entry: Track { get }
}

struct Populars: Codable {
    let populars: [PopularEntry]
}

struct PopularEntry: Codable, TopEntry {
    let track: Track
    var entry: Track { return track }
    let playbackCount: Int
}
