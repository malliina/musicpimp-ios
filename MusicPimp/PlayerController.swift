//
//  PlaybackController.swift
//  MusicPimp
//
//  Created by Michael Skogberg on 12/04/15.
//  Copyright (c) 2015 Skogberg Labs. All rights reserved.
//

import Foundation
import UIKit

fileprivate extension Selector {
    static let volumeClicked = #selector(PlayerController.onVolumeBarButtonClicked)
    static let seekChanged = #selector(PlayerController.sliderChanged(_:))
}

class PlayerController: ListeningController, PlaybackDelegate {
    static let seekThumbImage = UIImage(named: "oval-32.png")
    
    let defaultPosition = Duration.Zero
    let defaultDuration = 60.seconds
    
    let playbackFooter = SnapPlaybackFooter()
    let titleLabel = UILabel()
    let albumLabel = UILabel()
    let artistLabel = UILabel()
    let seek = UISlider()
    let positionLabel = UILabel()
    let durationLabel = UILabel()
    
    let coverContainer = UIView()
    let coverImage: UIImageView = UIImageView()
    
    let minHeightForNav: CGFloat = 450
    
    override func viewDidLoad() {
        super.viewDidLoad()
        edgesForExtendedLayout = []
        navigationItem.title = "PLAYER"
        navigationItem.rightBarButtonItem = UIBarButtonItem(image: UIImage(icon: "fa-volume-up", backgroundColor: UIColor.clear, iconColor: UIColor.blue, fontSize: 24), style: .plain, target: self, action: .volumeClicked)
        initUI()
        listenWhenLoaded(player)
        albumLabel.textColor = PimpColors.subtitles
        positionLabel.textColor = PimpColors.subtitles
        durationLabel.textColor = PimpColors.subtitles
        updateNavigationBarVisibility(self.view.frame.size.height)
        
        if let thumbImage = PlayerController.seekThumbImage {
            seek.setThumbImage(imageWithSize(image: thumbImage, scaledToSize: CGSize(width: 8, height: 8)), for: .normal)
        }
    }
    
    func onVolumeBarButtonClicked() {
        // presents volume viewcontroller modally
        let dest = VolumeViewController()
        self.present(UINavigationController(rootViewController: dest), animated: true, completion: nil)
    }
    
    func initUI() {
        addSubviews(views: [playbackFooter, seek, positionLabel, durationLabel, artistLabel, albumLabel, titleLabel, coverContainer])
        baseConstraints(views: [playbackFooter, seek, artistLabel, albumLabel, titleLabel, coverContainer])
        initPlaybackFooter()
        initSeek()
        initLabels()
        initCover()
    }
    
    func initPlaybackFooter() {
        playbackFooter.delegate = self
        playbackFooter.setSizes(prev: 24, playPause: 32, next: 24)
        playbackFooter.snp.makeConstraints { make in
            make.bottom.equalToSuperview()
            make.height.equalTo(66)
            make.top.equalTo(seek.snp.bottom).offset(16)
        }
    }
    
    func initSeek() {
        // only triggers valueChanged when dragging has ended
        seek.isContinuous = false
        seek.addTarget(self, action: .seekChanged, for: .valueChanged)
        seek.snp.makeConstraints { make in
            make.top.equalTo(positionLabel.snp.bottom).offset(2)
            make.top.equalTo(durationLabel.snp.bottom).offset(2)
        }
        positionLabel.textAlignment = .left
        positionLabel.snp.makeConstraints { make in
            make.leading.equalTo(self.view.snp.leadingMargin)
            make.top.equalTo(artistLabel.snp.bottom).offset(8)
            make.trailing.equalTo(durationLabel.snp.leading)
            make.width.equalTo(durationLabel)
        }
        durationLabel.textAlignment = .right
        durationLabel.snp.makeConstraints { make in
            make.trailing.equalTo(self.view.snp.trailingMargin)
            make.top.equalTo(artistLabel.snp.bottom).offset(8)
        }
    }
    
    func initLabels() {
        centered(labels: [titleLabel, albumLabel, artistLabel])
        titleLabel.setContentCompressionResistancePriority(UILayoutPriorityRequired, for: .vertical)
        titleLabel.font = UIFont.systemFont(ofSize: 28)
        titleLabel.snp.makeConstraints { make in
            make.top.equalTo(coverContainer.snp.bottom).offset(16)
        }
        albumLabel.setContentCompressionResistancePriority(UILayoutPriorityRequired, for: .vertical)
        albumLabel.font = UIFont.systemFont(ofSize: 17)
        albumLabel.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(8)
        }
        artistLabel.font = UIFont.systemFont(ofSize: 17)
        artistLabel.setContentCompressionResistancePriority(UILayoutPriorityRequired, for: .vertical)
        artistLabel.snp.makeConstraints { make in
            make.top.equalTo(albumLabel.snp.bottom).offset(8)
        }
    }
    
    func initCover() {
        coverContainer.snp.makeConstraints { make in
            make.top.equalTo(self.view.snp.topMargin).offset(8)
            make.bottom.equalTo(titleLabel.snp.top).offset(-16)
            make.leading.equalTo(self.view.snp.leadingMargin)
            make.trailing.equalTo(self.view.snp.trailingMargin)
        }
        coverContainer.addSubview(coverImage)
        coverImage.image = CoverService.defaultCover
        coverImage.snp.makeConstraints { make in
            make.top.greaterThanOrEqualToSuperview()
            make.bottom.lessThanOrEqualToSuperview()
            make.centerY.equalToSuperview()
            make.centerX.equalToSuperview()
        }
        coverImage.contentMode = .scaleAspectFit
    }
    
    func centered(labels: [UILabel]) {
        labels.forEach { label in
            label.textAlignment = .center
            label.numberOfLines = 0
        }
    }
    
    // TODO source? SO?
    func imageWithSize(image: UIImage, scaledToSize newSize: CGSize) -> UIImage {
        UIGraphicsBeginImageContextWithOptions(newSize, false, 0.0);
        image.draw(in: CGRect(origin: CGPoint(x: 0,y: 0), size: CGSize(width: newSize.width, height: newSize.height)))
        let newImage: UIImage = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        return newImage
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        updateNavigationBarVisibility(size.height)
    }
    
    func updateNavigationBarVisibility(_ height: CGFloat) {
        let isHidden = height < minHeightForNav
        self.navigationController?.setNavigationBarHidden(isHidden, animated: true)
    }
    
    func updatePlayPause(_ isPlaying: Bool) {
        playbackFooter.updatePlayPause(isPlaying: isPlaying)
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
        let isUserDragging = seek.isHighlighted
        if !isUserDragging {
            seek.value = position.secondsFloat
        }
        positionLabel.text = position.description
    }
    
    override func onTimeUpdated(_ position: Duration) {
        updatePosition(position)
    }
    
    override func onStateChanged(_ state: PlaybackState) {
        updatePlayPause(state == .Playing)
    }
    
    func onPrev() {
        _ = limitChecked {
            self.player.prev()
        }
    }
    
    func onPlayPause() {
        playOrPause()
    }
    
    func onNext() {
        _ = limitChecked {
            self.player.next()
        }
    }
    
    fileprivate func playOrPause() {
        if player.current().isPlaying {
            _ = self.player.pause()
        } else {
            _ = limitChecked {
                self.player.play()
            }
        }
    }
    
    func sliderChanged(_ sender: AnyObject) {
        let seekValue = seek.value
        // TODO throttle
        if let pos = seekValue.seconds {
            _ = limitChecked {
                self.player.seek(pos)
            }
        } else {
            Log.info("Unable to convert value to Duration: \(seekValue)")
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
