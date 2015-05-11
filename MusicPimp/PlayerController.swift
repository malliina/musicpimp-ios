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
    var player = LocalPlayer.sharedInstance
    
    @IBOutlet var playPause: UIButton!
    
    @IBOutlet var pause: UIButton!
    
    @IBOutlet var seek: UISlider!
    
    private var listeners: [Disposable] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    override func viewWillAppear(animated: Bool) {
        let listener = player.timeEvent.addHandler(self, handler: { (pc) -> Float -> () in
            pc.onTimeUpdated
        })
        let trackListener = player.trackEvent.addHandler(self, handler: { (pc) -> Track -> () in
            pc.updateTrack
        })
        if let track = player.playerInfo?.track {
            updateTrack(track)
        }
        listeners = [listener, trackListener]
    }
    override func viewDidDisappear(animated: Bool) {
        for listener in listeners {
            listener.dispose()
        }
        listeners = []
    }
    private func updateTrack(track: Track) {
        let duration = player.duration() ?? defaultDuration
        seek.maximumValue = duration
        let position = player.position() ?? defaultPosition
        seek.setValue(position, animated: true)
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