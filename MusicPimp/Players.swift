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
        let suggestLocal = localOutputs.count > 0 && !isLocal()
        let suggestRemote = localOutputs.count == 0 && isLocal()
        if suggestLocal {
            suggestHandover(to: Endpoint.Local, suggestedName: localOutputs[0], view: view)
        }
        if suggestRemote {
            let to = PimpSettings.sharedInstance.activeLibrary()
            suggestHandover(to: to, suggestedName: to.name, view: view)
        }
    }
    
    func suggestHandover(to: Endpoint, suggestedName: String, view: UIViewController) {
        let isToLocal = to.id == Endpoint.Local.id
        let player = PimpSettings.sharedInstance.activePlayer()
        let sheet = UIAlertController(title: "Listening on \(player.name)", message: "Change to \(suggestedName)?", preferredStyle: .alert)
        let handoverChoice = isToLocal ? "Change to \(suggestedName)" : "Change to \(suggestedName) with handover"
        let handoverAction = UIAlertAction(title: handoverChoice, style: .default) { a in
            self.performHandover(to: to)
        }
        sheet.addAction(handoverAction)
        if !isToLocal {
            let changeAction = UIAlertAction(title: "Change to \(suggestedName)", style: .default) { a in
                self.changePlayer(to: to)
            }
            sheet.addAction(changeAction)
        }
        let cancelAction = UIAlertAction(title: "Continue on \(player.name)", style: .cancel, handler: nil)
        sheet.addAction(cancelAction)
        if let popover = sheet.popoverPresentationController {
            popover.sourceView = view.view
        }
        view.present(sheet, animated: true, completion: nil)
    }
    
    func changePlayer(to: Endpoint) {
        pauseCurrent()
        PlayerManager.sharedInstance.use(endpoint: to)
    }
    
    func performHandover(to: Endpoint) {
        let currentState = PlayerManager.sharedInstance.active.current()
        pauseCurrent()
        PlayerManager.sharedInstance.use(endpoint: to) { p in let _ = p.handover(state: currentState) }
    }
    
    func pauseCurrent() {
        if let error = PlayerManager.sharedInstance.active.pause() {
            self.log.warn("Unable to pause player: \(error)")
        }
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
    
    func isLocal() -> Bool {
        return PlayerManager.sharedInstance.active.isLocal
    }
}
