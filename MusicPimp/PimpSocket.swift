//
//  PimpSocket.swift
//  MusicPimp
//
//  Created by Michael Skogberg on 31/05/15.
//  Copyright (c) 2015 Skogberg Labs. All rights reserved.
//

import Foundation

class PimpSocket: PlayerSocket {
    private let log = LoggerFactory.pimp("Pimp.PimpSocket", category: "Pimp")
    
    let limiter = Limiter.sharedInstance
    
    var delegate: PlayerEventDelegate = LoggingDelegate()
    
    init(baseURL: URL, authValue: String) {
        let headers = [
            HttpClient.AUTHORIZATION: authValue,
            HttpClient.ACCEPT: PimpHttpClient.PIMP_VERSION_18
        ]
        super.init(baseURL: baseURL, headers: headers)
    }
    
    func send(_ dict: [String: AnyObject]) -> ErrorMessage? {
        if let socket = socket {
            if let payload = Json.stringifyObject(dict, prettyPrinted: false) {
                socket.send(payload)
                //Log.info("Sent \(payload) to \(baseURL))")
                return nil
            } else {
                return failWith("Unable to send payload, encountered non-JSON payload: \(dict)")
            }
        } else {
            return failWith("Unable to send payload, socket not available.")
        }
        
    }
    
    func failWith(_ message: String) -> ErrorMessage {
        log.error(message)
        return ErrorMessage(message: message)
    }
    
    override func webSocket(_ webSocket: SRWebSocket!, didReceiveMessage message: Any!) {
        if let message = message as? String {
            //Log.info("Got message \(message)")
            if let dict = Json.asJson(message) as? NSDictionary {
                if let event = dict[JsonKeys.EVENT] as? String {
                    switch event {
                    case JsonKeys.TIME_UPDATED:
                        if let position = dict[JsonKeys.POSITION] as? Int {
                            delegate.onTimeUpdated(position.seconds)
                        }
                        break
                    case JsonKeys.TRACK_CHANGED:
                        if let track = dict[JsonKeys.TRACK] as? NSDictionary {
                            if let track = try? delegate.parseTrack(track) {
                                delegate.onTrackChanged(track)
                            } else {
                                log.error("Unable to parse track: \(message)")
                            }
                        }
                        break
                    case JsonKeys.MUTE_TOGGLED:
                        if let mute = dict[JsonKeys.MUTE] as? Bool {
                            delegate.onMuteToggled(mute)
                        }
                        break
                    case JsonKeys.VOLUME_CHANGED:
                        if let volume = dict[JsonKeys.VOLUME] as? Int {
                            delegate.onVolumeChanged(VolumeValue(volume: volume))
                        }
                        break
                    case JsonKeys.PLAYSTATE_CHANGED:
                        if let stateName = dict[JsonKeys.STATE] as? String {
                            if let state = PlaybackState.fromName(stateName) {
                                delegate.onStateChanged(state)
                            } else {
                                log.error("Unknown playback state name: \(stateName)")
                            }
                        }
                        break
                    case JsonKeys.INDEX_CHANGED:
                        if let index = dict[JsonKeys.PLAYLIST_INDEX] as? Int {
                            let idx: Int? = index >= 0 ? index : nil
                            delegate.onIndexChanged(idx)
                        }
                        break
                    case JsonKeys.PLAYLIST_MODIFIED:
                        if let list = dict[JsonKeys.PLAYLIST] as? [NSDictionary] {
                            if let tracks = try? list.map(self.delegate.parseTrack) {
                                delegate.onPlaylistModified(tracks)
                            } else {
                                log.error("Unable to parse tracks: \(message)")
                            }
                        }
                        break
                    case JsonKeys.STATUS:
                        if let state = try? delegate.parseStatus(dict) {
                            delegate.onState(state)
                        } else {
                            log.error("Unable to parse status: \(message)")
                        }
                        break
                    case JsonKeys.WELCOME:
                        socket?.send(Json.stringifyObject([JsonKeys.CMD: JsonKeys.STATUS as AnyObject]))
                        break
                    case JsonKeys.PING:
                        break
                    default:
                        log.error("Unknown event: \(event)")
                    }
                }
            } else {
                log.error("Message is not a JSON object: \(message)")
            }
        } else {
            log.error("WebSocket message is not a string: \(message)")
        }
    }
}
