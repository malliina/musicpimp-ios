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
    let defaultDuration = Float(100)
    let defaultPosition = Float(0)
    var playerManager: PlayerManager { get { return PlayerManager.sharedInstance } }
    var player: PlayerType { get { return playerManager.active } }
    
    @IBOutlet var titleLabel: UILabel!
    
    @IBOutlet var albumLabel: UILabel!
    
    @IBOutlet var artistLabel: UILabel!
    
    @IBOutlet var playPause: UIButton!
    
    @IBOutlet var pause: UIButton!
    
    @IBOutlet var seek: UISlider!
    
    private var listeners: [Disposable] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        playerManager.playerChanged.addHandler(self, handler: { (pc) -> PlayerType -> () in
            pc.onNewPlayer
        })
    }
    override func viewWillAppear(animated: Bool) {
        listen(player)
        let current = player.current()
        if let track = current.track {
            updateTrack(track)
            seek.value = Float(current.position)
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
        let listener = targetPlayer.timeEvent.addHandler(self, handler: { (pc) -> Float -> () in
            pc.onTimeUpdated
        })
        let trackListener = targetPlayer.trackEvent.addHandler(self, handler: { (pc) -> Track -> () in
            pc.updateTrack
        })
        listeners = [listener, trackListener]

    }
    private func unlisten() {
        for listener in listeners {
            listener.dispose()
        }
        listeners = []
    }
    private func updateNoMedia() {
        seek.value = defaultPosition
        seek.maximumValue = defaultDuration
        titleLabel.text = "No track"
        albumLabel.text = ""
        artistLabel.text = ""
    }
    private func updateTrack(track: Track) {
        seek.value = Float(0)
        seek.maximumValue = Float(track.duration)
        titleLabel.text = track.title
        albumLabel.text = track.album
        artistLabel.text = track.artist
    }
    private func onTimeUpdated(position: Float) {
        seek.setValue(position, animated: true)
    }
    @IBAction func playClicked(sender: AnyObject) {
        player.play()
    }
    @IBAction func pauseClicked(sender: AnyObject) {
        player.pause()
    }
    @IBAction func sliderChanged(sender: AnyObject) {
        // TODO throttle
        info("Seek to \(seek.value)")
        player.seek(seek.value)
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