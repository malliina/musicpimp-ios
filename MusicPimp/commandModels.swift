import Foundation

struct SimpleCommand: Codable {
    let cmd: String
}

// Playlist commands

struct AddTrackPayload: Codable {
    let cmd: String
    let track: TrackID
}

struct IntPayload: Codable {
    let cmd: String
    let value: Int
    
    init(removeAt: Int) {
        self.cmd = JsonKeys.REMOVE
        self.value = removeAt
    }
    
    init(volumeChanged to: Int) {
        self.cmd = JsonKeys.VOLUME
        self.value = to
    }
    
    init(skip to: Int) {
        self.cmd = JsonKeys.SKIP
        self.value = to
    }
    
    init(seek to: Duration) {
        self.cmd = JsonKeys.SEEK
        self.value = Int(to.seconds)
    }
}

struct MoveTrack: Codable {
    let cmd: String
    let from: Int
    let to: Int
}

struct ResetPlaylistPayload: Codable {
    let cmd: String
    let index: Int
    let tracks: [TrackID]
}

/// Player commands

struct PlayItems: Codable {
    let cmd: String
    let tracks: [TrackID]
    let folders: [FolderID]
    
    init(tracks: [Track]) {
        self.cmd = "play_items"
        self.tracks = tracks.map { $0.id }
        self.folders = []
    }
}

/// Alarms

struct SaveAlarm: Codable {
    let cmd: String = JsonKeys.Save
    let ap: AlarmJson<AlarmJobIdOnly>
    let enabled: Bool
}

struct DeleteAlarm: Codable {
    let cmd: String = JsonKeys.DELETE
    let id: AlarmID
}

/// Various

struct RegisterPush: Codable {
    let cmd: String = JsonKeys.ApnsAdd
    let id: PushToken
    let tag: String
}

struct UnregisterPush: Codable {
    let cmd: String = JsonKeys.ApnsRemove
    let id: String
}

struct PushNotification: Codable {
    let cmd: String
    let tag: String
}
