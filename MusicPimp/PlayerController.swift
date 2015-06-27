//
//  PlaybackController.swift
//  MusicPimp
//
//  Created by Michael Skogberg on 12/04/15.
//  Copyright (c) 2015 Skogberg Labs. All rights reserved.
//

import Foundation
import UIKit

class PlayerController: UIViewController {
    let defaultPosition = Duration.Zero
    let defaultDuration = Duration(seconds: 60)
    var playerManager: PlayerManager { get { return PlayerManager.sharedInstance } }
    var player: PlayerType { get { return playerManager.active } }
    
    @IBOutlet var titleLabel: UILabel!
    
    @IBOutlet var albumLabel: UILabel!
    
    @IBOutlet var artistLabel: UILabel!
    
    @IBOutlet var playPause: UIButton!
    
    @IBOutlet var pause: UIButton!
    
    @IBOutlet var prevButton: UIButton!
    @IBOutlet var nextButton: UIButton!
    @IBOutlet var seek: UISlider!
    @IBOutlet var positionLabel: UILabel!
    @IBOutlet var durationLabel: UILabel!
    
    private var listeners: [Disposable] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        playerManager.playerChanged.addHandler(self, handler: { (pc) -> PlayerType -> () in
            pc.onNewPlayer
        })
        setFontAwesomeTitle(pause, fontAwesomeName: "fa-play")
        setFontAwesomeTitle(prevButton, fontAwesomeName: "fa-step-backward")
        setFontAwesomeTitle(nextButton, fontAwesomeName: "fa-step-forward")
    }
    func updatePlayPause(isPlaying: Bool) {
        let faIcon = isPlaying ? "fa-pause" : "fa-play"
        setFontAwesomeTitle(pause, fontAwesomeName: faIcon)
    }
    func setFontAwesomeTitle(button: UIButton, fontAwesomeName: String) {
        let buttonText = String.fontAwesomeIconStringForIconIdentifier(fontAwesomeName)
        button.setTitle(buttonText, forState: UIControlState.Normal)
    }
    
    override func viewWillAppear(animated: Bool) {
        listen(player)
        let current = player.current()
        updatePlayPause(current.isPlaying)
        if let track = current.track {
            updateTrack(track)
            seek.value = Float(current.position.seconds)
        } else {
            updateNoMedia()
        }
    }
    override func viewDidDisappear(animated: Bool) {
        unlisten()
    }
    func onNewPlayer(newPlayer: PlayerType) {
        unlisten()
        listen(newPlayer)
    }
    private func listen(targetPlayer: PlayerType) {
        let listener = targetPlayer.timeEvent.addHandler(self, handler: { (pc) -> Duration -> () in
            pc.onTimeUpdated
        })
        let trackListener = targetPlayer.trackEvent.addHandler(self, handler: { (pc) -> Track? -> () in
            pc.updateTrack
        })
        let stateListener = targetPlayer.stateEvent.addHandler(self, handler: { (pc) -> PlaybackState -> () in
            pc.onStateChanged
        })
        listeners = [listener, trackListener, stateListener]

    }
    private func unlisten() {
        for listener in listeners {
            listener.dispose()
        }
        listeners = []
    }
    private func updateTrack(track: Track?) {
        if let track = track {
            updateMedia(track)
        } else {
            updateNoMedia()
        }
    }
    private func updateNoMedia() {
        updatePlayPause(false)
        updateDuration(defaultDuration)
        updatePosition(defaultPosition)
        titleLabel.text = "No track"
        albumLabel.text = ""
        artistLabel.text = ""
    }
    private func updateMedia(track: Track) {
        updateDuration(track.duration)
        //updatePosition(defaultPosition)
        titleLabel.text = track.title
        albumLabel.text = track.album
        artistLabel.text = track.artist
    }
    private func updateDuration(duration: Duration) {
        seek.maximumValue = duration.secondsFloat
        durationLabel.text = duration.description
    }
    private func updatePosition(position: Duration) {
        seek.value = position.secondsFloat
        positionLabel.text = position.description
    }
    private func onTimeUpdated(position: Duration) {
        updatePosition(position)
    }
    private func onStateChanged(state: PlaybackState) {
        updatePlayPause(state == .Playing)
    }
    @IBAction func playClicked(sender: AnyObject) {
        player.play()
    }
    @IBAction func pauseClicked(sender: AnyObject) {
        if player.current().isPlaying {
            player.pause()
        } else {
            player.play()
        }
    }
    @IBAction func sliderChanged(sender: AnyObject) {
        let seekValue = seek.value
        // TODO throttle
        if let pos = seekValue.seconds {
            info("Seek to \(seekValue)")
            player.seek(pos)
        } else {
            Log.info("Unable to convert value to Duration: \(seekValue)")
        }
    }
    @IBAction func nextClicked(sender: AnyObject) {
        player.next()
    }
    @IBAction func previousClicked(sender: AnyObject) {
        player.prev()
    }
    func info(s: String) {
        Log.info(s)
    }
}