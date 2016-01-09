//
//  PimpSocket.swift
//  MusicPimp
//
//  Created by Michael Skogberg on 31/05/15.
//  Copyright (c) 2015 Skogberg Labs. All rights reserved.
//

import Foundation

class PimpSocket: PlayerSocket {
    let limiter = Limiter.sharedInstance
    
    var delegate: PlayerEventDelegate = LoggingDelegate()
    
    init(baseURL: String, authValue: String) {
        let headers = [
            HttpClient.AUTHORIZATION: authValue,
            HttpClient.ACCEPT: PimpHttpClient.PIMP_VERSION_18
        ]
        super.init(baseURL: baseURL, headers: headers)
    }
    
    func send(dict: [String: AnyObject]) -> Bool {
        if let payload = Json.stringifyObject(dict, prettyPrinted: false), socket = socket {
            if limiter.isWithinLimit() {
                socket.send(payload)
                return true
            } else {
                PurchaseHelper.sharedInstance.suggestPremium()
            }
        }
        return false
    }
    
    override func webSocket(webSocket: SRWebSocket!, didReceiveMessage message: AnyObject!) {
        if let message = message as? String {
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
                            delegate.onTrackChanged(delegate.parseTrack(track))
                        }
                        break
                    case JsonKeys.MUTE_TOGGLED:
                        if let mute = dict[JsonKeys.MUTE] as? Bool {
                            delegate.onMuteToggled(mute)
                        }
                        break
                    case JsonKeys.VOLUME_CHANGED:
                        if let volume = dict[JsonKeys.VOLUME] as? Int {
                            delegate.onVolumeChanged(volume)
                        }
                        break
                    case JsonKeys.PLAYSTATE_CHANGED:
                        if let stateName = dict[JsonKeys.STATE] as? String {
                            if let state = PlaybackState.fromName(stateName) {
                                delegate.onStateChanged(state)
                            } else {
                                Log.error("Unknown playback state name: \(stateName)")
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
                            let tracks = list.flatMapOpt({ self.delegate.parseTrack($0) })
                            delegate.onPlaylistModified(tracks)
                        }
                        break
                    case JsonKeys.STATUS:
                        if let state = delegate.parseStatus(dict) {
                            delegate.onState(state)
                        } else {
                            Log.error("Unable to parse status: \(message)")
                        }
                        break
                    case JsonKeys.WELCOME:
                        socket?.send(Json.stringifyObject([JsonKeys.CMD: JsonKeys.STATUS]))
                        break
                    case JsonKeys.PING:
                        break
                    default:
                        Log.error("Unknown event: \(event)")
                    }
                }
            } else {
                Log.error("Message is not a JSON object: \(message)")
            }
        } else {
            Log.error("WebSocket message is not a string: \(message)")
        }
    }
}
