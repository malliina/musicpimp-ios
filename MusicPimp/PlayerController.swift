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
    
    @IBOutlet var volumeBarButton: UIBarButtonItem!
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
    
    @IBOutlet var coverImage: UIImageView!
    
    private var loadedListeners: [Disposable] = []
    private var appearedListeners: [Disposable] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let volumeIconFontSize: Int32 = 24
        volumeBarButton.image = UIImage(icon: "fa-volume-up", backgroundColor: UIColor.clearColor(), iconColor: UIColor.blueColor(), fontSize: volumeIconFontSize)
        listenWhenLoaded(player)
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
        listenWhenAppeared(player)
        let current = player.current()
        updatePlayPause(current.isPlaying)
        if let track = current.track {
            updateTrack(track)
            seek.value = current.position.secondsFloat
        } else {
            updateNoMedia()
        }
    }
    
    override func viewDidDisappear(animated: Bool) {
        unlistenWhenAppeared()
    }
    
    func onNewPlayer(newPlayer: PlayerType) {
        reinstallListeners(newPlayer)
    }
    
    private func listenWhenLoaded(targetPlayer: PlayerType) {
        let trackListener = targetPlayer.trackEvent.addHandler(self, handler: { (pc) -> Track? -> () in
            pc.updateTrack
        })
        loadedListeners = [trackListener]
    }
    
    private func unlistenWhenLoaded() {
        for listener in loadedListeners {
            listener.dispose()
        }
        loadedListeners = []
    }
    
    private func listenWhenAppeared(targetPlayer: PlayerType) {
        unlistenWhenAppeared()
        let listener = targetPlayer.timeEvent.addHandler(self, handler: { (pc) -> Duration -> () in
            pc.onTimeUpdated
        })
        let stateListener = targetPlayer.stateEvent.addHandler(self, handler: { (pc) -> PlaybackState -> () in
            pc.onStateChanged
        })
        appearedListeners = [listener, stateListener]
    }
    
    private func unlistenWhenAppeared() {
        for listener in appearedListeners {
            listener.dispose()
        }
        appearedListeners = []
    }
    
    private func reinstallListeners(targetPlayer: PlayerType) {
        unlistenWhenAppeared()
        unlistenWhenLoaded()
        listenWhenLoaded(targetPlayer)
        listenWhenAppeared(targetPlayer)
    }
    
    private func updateTrack(track: Track?) {
        if let track = track {
            updateMedia(track)
        } else {
            updateNoMedia()
        }
    }
    
    private func updateNoMedia() {
        Util.onUiThread {
            self.updatePlayPause(false)
            self.updateDuration(self.defaultDuration)
            self.updatePosition(self.defaultPosition)
            self.titleLabel.text = "No track"
            self.albumLabel.text = ""
            self.artistLabel.text = ""
        }
    }
    
    private func updateMedia(track: Track) {
        Util.onUiThread {
            self.updateDuration(track.duration)
            self.titleLabel.text = track.title
            self.albumLabel.text = track.album
            self.artistLabel.text = track.artist
            self.updateCover(track)
        }
    }
    
    private func updateCover(track: Track) {
        CoverService.sharedInstance.cover(track.artist, album: track.album) {
            (result) -> () in
            var image = CoverService.defaultCover
            // the track may have changed between the time the cover was requested and received
            if let imageResult = result.image where self.player.current().track?.title == track.title {
                image = imageResult
            }
            if let image = image {
//                let picker = DBImageColorPicker(fromImage: image, withBackgroundType: DBImageColorPickerBackgroundType.Default)
//                let newBackground = picker.backgroundColor
//                let isLight = newBackground.isLight()
//                self.info("isLight \(isLight) \(newBackground.description)")
                Util.onUiThread {
//                    self.view.backgroundColor = newBackground
                    self.coverImage.image = image
                }
            }
        }
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

extension UIColor
{
    // http://stackoverflow.com/a/29044899
    func isLight() -> Bool
    {
        let components = CGColorGetComponents(self.CGColor)
        let first = components[0] * 299
        let second = components[1] * 587
        let third = components[2] * 114
        let brightness = (first + second + third) / 1000
        
        if brightness < 0.5
        {
            return false
        }
        else
        {
            return true
        }
    }
}