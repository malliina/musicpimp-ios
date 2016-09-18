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
    
    @IBOutlet var labelContainer: UIView!
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
    
    let playIconName = "fa-play"
    
    let minHeightForNav: CGFloat = 450
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let volumeIconFontSize: Int32 = 24
        volumeBarButton.image = UIImage(icon: "fa-volume-up", backgroundColor: UIColor.clear, iconColor: UIColor.blue, fontSize: volumeIconFontSize)
        listenWhenLoaded(player)
//        labelContianer.backgroundColor = PimpColors.background
        pause.setFontAwesomeTitle(playIconName)
        prevButton.setFontAwesomeTitle("fa-step-backward")
        nextButton.setFontAwesomeTitle("fa-step-forward")
        self.labelContainer.backgroundColor = PimpColors.background
        albumLabel.textColor = PimpColors.subtitles
        positionLabel.textColor = PimpColors.subtitles
        durationLabel.textColor = PimpColors.subtitles
        updateNavigationBarVisibility(self.view.frame.size.height)
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        updateNavigationBarVisibility(size.height)
    }
    
    func updateNavigationBarVisibility(_ height: CGFloat) {
        let isHidden = height < minHeightForNav
        self.navigationController?.setNavigationBarHidden(isHidden, animated: true)
    }
    
    func updatePlayPause(_ isPlaying: Bool) {
        let faIcon = isPlaying ? "fa-pause" : playIconName
        pause.setFontAwesomeTitle(faIcon)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        let current = player.current()
        updatePlayPause(current.isPlaying)
        if let track = current.track {
            updateTrack(track)
            updatePosition(current.position)
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
    
    override func updateMedia(_ track: Track) {
        Util.onUiThread {
            self.updateDuration(track.duration)
            self.titleLabel.text = track.title
            self.albumLabel.text = track.album
            self.artistLabel.text = track.artist
            self.updateCover(track)
        }
    }
    
    fileprivate func updateCover(_ track: Track) {
        CoverService.sharedInstance.cover(track.artist, album: track.album) {
            (result) -> () in
            var image = CoverService.defaultCover
            // the track may have changed between the time the cover was requested and received
            if let imageResult = result.image , self.player.current().track?.title == track.title {
                image = imageResult
            }
            if let image = image {
                Util.onUiThread {
                    self.coverImage.image = image
                }
            }
        }
    }
    
    fileprivate func updateDuration(_ duration: Duration) {
        seek.maximumValue = duration.secondsFloat
        durationLabel.text = duration.description
    }
    
    fileprivate func updatePosition(_ position: Duration) {
        seek.value = position.secondsFloat
        positionLabel.text = position.description
    }
    
    override func onTimeUpdated(_ position: Duration) {
        updatePosition(position)
    }
    
    override func onStateChanged(_ state: PlaybackState) {
        updatePlayPause(state == .Playing)
    }
    
    @IBAction func pauseClicked(_ sender: AnyObject) {
        self.playOrPause()
    }
    
    fileprivate func playOrPause() {
        if player.current().isPlaying {
            self.player.pause()
        } else {
            limitChecked {
                self.player.play()
            }
        }
    }
    
    @IBAction func sliderChanged(_ sender: AnyObject) {
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
    
    @IBAction func nextClicked(_ sender: AnyObject) {
        limitChecked {
            self.player.next()
        }
    }
    
    @IBAction func previousClicked(_ sender: AnyObject) {
        limitChecked {
            self.player.prev()
        }
    }
    
    func info(_ s: String) {
        Log.info(s)
    }
}

extension UIButton {
    func setFontAwesomeTitle(_ fontAwesomeName: String) {
        let buttonText = String.fontAwesomeIconString(forIconIdentifier: fontAwesomeName)
        self.setTitle(buttonText, for: UIControlState())
    }
}

extension UIColor
{
    // http://stackoverflow.com/a/29044899
    func isLight() -> Bool
    {
        let components = self.cgColor.components
        let first = (components?[0])! * 299
        let second = (components?[1])! * 587
        let third = (components?[2])! * 114
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
        let oldFontDescriptor = fontDescriptor
        let newFontDescriptor = oldFontDescriptor.monospacedDigitFontDescriptor
        return UIFont(descriptor: newFontDescriptor, size: 0)
    }
    
}

private extension UIFontDescriptor {
    
    var monospacedDigitFontDescriptor: UIFontDescriptor {
        let fontDescriptorFeatureSettings = [[UIFontFeatureTypeIdentifierKey: kNumberSpacingType, UIFontFeatureSelectorIdentifierKey: kMonospacedNumbersSelector]]
        let fontDescriptorAttributes = [UIFontDescriptorFeatureSettingsAttribute: fontDescriptorFeatureSettings]
        let fontDescriptor = self.addingAttributes(fontDescriptorAttributes)
        return fontDescriptor
    }
    
}
