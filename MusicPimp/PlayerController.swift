//
//  PlaybackController.swift
//  MusicPimp
//
//  Created by Michael Skogberg on 12/04/15.
//  Copyright (c) 2015 Skogberg Labs. All rights reserved.
//

import Foundation
import UIKit

class PlayerController: ListeningController {
    let defaultPosition = Duration.Zero
    let defaultDuration = 60.seconds
    
    @IBOutlet var volumeBarButton: UIBarButtonItem!
    @IBOutlet var titleLabel: UILabel!
    @IBOutlet var albumLabel: UILabel!
    @IBOutlet var artistLabel: UILabel!
    @IBOutlet var pause: UIButton!
    @IBOutlet var prevButton: UIButton!
    @IBOutlet var nextButton: UIButton!
    @IBOutlet var seek: UISlider!
    @IBOutlet var positionLabel: UILabel!
    @IBOutlet var durationLabel: UILabel!
    
    @IBOutlet var coverImage: UIImageView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let volumeIconFontSize: Int32 = 24
        volumeBarButton.image = UIImage(icon: "fa-volume-up", backgroundColor: UIColor.clearColor(), iconColor: UIColor.blueColor(), fontSize: volumeIconFontSize)
        listenWhenLoaded(player)
        playerManager.playerChanged.addHandler(self, handler: { (pc) -> PlayerType -> () in
            pc.onNewPlayer
        })
        pause.setFontAwesomeTitle("fa-play")
        prevButton.setFontAwesomeTitle("fa-step-backward")
        nextButton.setFontAwesomeTitle("fa-step-forward")
    }
    
    func updatePlayPause(isPlaying: Bool) {
        let faIcon = isPlaying ? "fa-pause" : "fa-play"
        pause.setFontAwesomeTitle(faIcon)
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        let current = player.current()
        updatePlayPause(current.isPlaying)
        if let track = current.track {
            updateTrack(track)
            seek.value = current.position.secondsFloat
        } else {
            updateNoMedia()
        }
    }
    
    override func updateNoMedia() {
        Util.onUiThread {
            self.updatePlayPause(false)
            self.updateDuration(self.defaultDuration)
            self.updatePosition(self.defaultPosition)
            self.titleLabel.text = "No track"
            self.albumLabel.text = ""
            self.artistLabel.text = ""
        }
    }
    
    override func updateMedia(track: Track) {
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
                Util.onUiThread {
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
    
    override func onTimeUpdated(position: Duration) {
        updatePosition(position)
    }
    
    override func onStateChanged(state: PlaybackState) {
        updatePlayPause(state == .Playing)
    }
    
    @IBAction func pauseClicked(sender: AnyObject) {
        self.playOrPause()
    }
    
    private func playOrPause() {
        if player.current().isPlaying {
            self.player.pause()
        } else {
            limitChecked {
                self.player.play()
            }
        }
    }
    
    @IBAction func sliderChanged(sender: AnyObject) {
        let seekValue = seek.value
        // TODO throttle
        if let pos = seekValue.seconds {
            info("Seek to \(seekValue)")
            limitChecked {
                self.player.seek(pos)
            }
        } else {
            Log.info("Unable to convert value to Duration: \(seekValue)")
        }
    }
    
    @IBAction func nextClicked(sender: AnyObject) {
        limitChecked {
            self.player.next()
        }
    }
    
    @IBAction func previousClicked(sender: AnyObject) {
        limitChecked {
            self.player.prev()
        }
    }
    
    func info(s: String) {
        Log.info(s)
    }
}

extension UIButton {
    func setFontAwesomeTitle(fontAwesomeName: String) {
        let buttonText = String.fontAwesomeIconStringForIconIdentifier(fontAwesomeName)
        self.setTitle(buttonText, forState: UIControlState.Normal)
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

extension UIFont {
    
    var monospacedDigitFont: UIFont {
        let oldFontDescriptor = fontDescriptor()
        let newFontDescriptor = oldFontDescriptor.monospacedDigitFontDescriptor
        return UIFont(descriptor: newFontDescriptor, size: 0)
    }
    
}

private extension UIFontDescriptor {
    
    var monospacedDigitFontDescriptor: UIFontDescriptor {
        let fontDescriptorFeatureSettings = [[UIFontFeatureTypeIdentifierKey: kNumberSpacingType, UIFontFeatureSelectorIdentifierKey: kMonospacedNumbersSelector]]
        let fontDescriptorAttributes = [UIFontDescriptorFeatureSettingsAttribute: fontDescriptorFeatureSettings]
        let fontDescriptor = self.fontDescriptorByAddingAttributes(fontDescriptorAttributes)
        return fontDescriptor
    }
    
}