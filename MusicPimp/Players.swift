//
//  Players.swift
//  MusicPimp
//
//  Created by Michael Skogberg on 19/05/15.
//  Copyright (c) 2015 Skogberg Labs. All rights reserved.
//

import Foundation
import AVFoundation

class Players {
    static let sharedInstance = Players()
    let log = LoggerFactory.pimp("Audio.Players", category: "Audio")
    
    let audioPortTypes = [
        AVAudioSessionPortBluetoothHFP,
        AVAudioSessionPortBluetoothA2DP,
        AVAudioSessionPortCarAudio,
        AVAudioSessionPortHeadphones,
        AVAudioSessionPortAirPlay
    ]
    
    func fromEndpoint(_ e: Endpoint) -> PlayerType {
        let serverType = e.serverType
        switch serverType.name {
        case ServerTypes.MusicPimp.name:
            return PimpPlayer(e: e)
        case ServerTypes.Cloud.name:
            return PimpPlayer(e: e)
        default:
            return LocalPlayer.sharedInstance
        }
    }
    
    func suggestHandoverIfNecessary(view: UIViewController) {
        let localOutputs = describeLocalOutput()
        let suggestLocal = localOutputs.count > 0 && isNotLocal()
        if suggestLocal {
            let suggestedName = localOutputs[0]
            let player = PimpSettings.sharedInstance.activePlayer()
            let sheet = UIAlertController(title: "Listening on \(player.name)", message: "Change to \(suggestedName)?", preferredStyle: .alert)
            let okAction = UIAlertAction(title: suggestedName, style: .default) { a in
                self.performHandover(from: PlayerManager.sharedInstance.active, to: Endpoint.Local)
            }
            let cancelAction = UIAlertAction(title: player.name, style: .cancel) { a in
            }
            sheet.addAction(okAction)
            sheet.addAction(cancelAction)
            if let popover = sheet.popoverPresentationController {
                popover.sourceView = view.view
            }
            view.present(sheet, animated: true, completion: nil)
        }
    }
    
    func performHandover(from: PlayerType, to: Endpoint) {
        let currentState = from.current()
        if let error = from.pause() {
            self.log.warn("Unable to pause player: \(error)")
        }
        let newPlayer = PlayerManager.sharedInstance.use(endpoint: to)
        let _ = newPlayer.handover(state: currentState)
    }
    
    func describeLocalOutput() -> [String] {
        return AVAudioSession.sharedInstance().currentRoute.outputs.flatMapOpt { (desc) -> String? in
            switch desc.portType {
            case AVAudioSessionPortBluetoothHFP: return "Bluetooth"
            case AVAudioSessionPortBluetoothA2DP: return "Bluetooth"
            case AVAudioSessionPortCarAudio: return "Car Audio"
            case AVAudioSessionPortHeadphones: return "Headphones"
            case AVAudioSessionPortAirPlay: return "Air Play"
            default: return nil
            }
        }
    }
    
    func isNotLocal() -> Bool {
        return !PlayerManager.sharedInstance.active.isLocal
    }
}
