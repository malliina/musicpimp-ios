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
    let suggestAtMostEvery = 15.minutes
    private var lastLocalSuggestion: DispatchTime? = nil
    private var lastRemoteSuggestion: DispatchTime? = nil
    
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
    
    /// Shows a playback device selection dialog to the user if suitable conditions are met.
    ///
    /// Asks whether the user wants to start listening on:
    /// - this device, if connected to headphones or bluetooth
    /// - the server, if connected to neither headphones nor bluetooth
    ///
    func suggestPlayerChangeIfNecessary(view: UIViewController) {
        let isLocal = PlayerManager.sharedInstance.active.isLocal
        let localOutputs = describeLocalOutput()
        let now = DispatchTime.now()
        let suggestLocal = localOutputs.count > 0 && !isLocal && Util.hasTimePassed(time: suggestAtMostEvery, now: now, since: lastLocalSuggestion)
        let suggestRemote = localOutputs.count == 0 && isLocal && Util.hasTimePassed(time: suggestAtMostEvery, now: now, since: lastRemoteSuggestion)
        if suggestLocal {
            lastLocalSuggestion = now
            suggestPlayerChange(to: Endpoint.Local, suggestedName: localOutputs[0], isHandoverOptional: false, view: view)
        }
        if suggestRemote {
            let to = PimpSettings.sharedInstance.activeLibrary()
            if to.id != Endpoint.Local.id {
                lastRemoteSuggestion = now
                suggestPlayerChange(to: to, suggestedName: to.name, isHandoverOptional: true, view: view)
            }
        }
    }
    
    func suggestPlayerChange(to: Endpoint, suggestedName: String, isHandoverOptional: Bool, view: UIViewController) {
        let player = PimpSettings.sharedInstance.activePlayer()
        let sheet = UIAlertController(title: "Listening on \(player.name)", message: "Change to \(suggestedName)?", preferredStyle: .alert)
        let handoverChoice = isHandoverOptional ? "Change to \(suggestedName) with handover" : "Change to \(suggestedName)"
        let handoverAction = UIAlertAction(title: handoverChoice, style: .default) { a in
            self.performHandover(to: to)
        }
        sheet.addAction(handoverAction)
        if isHandoverOptional {
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
}
