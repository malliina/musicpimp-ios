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
    private let log = LoggerFactory.shared.vc(PlayerController.self)
    static let seekThumbImage = UIImage(named: "oval-32.png")
    
    let defaultPosition = Duration.Zero
    let defaultDuration = 60.seconds
    
    let titleLabel = PimpLabel.create()
    let albumLabel = UILabel()
    let artistLabel = PimpLabel.create()
    let seek = UISlider()
    let positionLabel = UILabel()
    let durationLabel = UILabel()
    
    let coverContainer = UIView()
    let coverImage: UIImageView = UIImageView()
    
    let minHeightForNav: CGFloat = 450

    override func viewDidLoad() {
        super.viewDidLoad()
        let img = UIImage(icon: "fa-volume-up", backgroundColor: UIColor.clear, iconColor: UIColor.blue, fontSize: 24)
        navigationItem.rightBarButtonItems = [ UIBarButtonItem(image: img, style: .plain, target: self, action: .volumeClicked) ]
        navigationItem.title = "PLAYER"
        initUI()
        albumLabel.textColor = colors.subtitles
        positionLabel.textColor = colors.subtitles
        durationLabel.textColor = colors.subtitles
        updateNavigationBarVisibility(self.view.frame.size.height)
        
        if let thumbImage = PlayerController.seekThumbImage {
            seek.setThumbImage(imageWithSize(image: thumbImage, scaledToSize: CGSize(width: 14, height: 14)), for: .normal)
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        let current = player.current()
        onTrackChanged(current.track)
        if current.track != nil {
            updatePosition(current.position)
        }
    }
    
    @objc func onVolumeBarButtonClicked() {
        // presents volume viewcontroller modally
        let dest = VolumeViewController()
        self.present(UINavigationController(rootViewController: dest), animated: true, completion: nil)
    }
    
    func initUI() {
        addSubviews(views: [seek, positionLabel, durationLabel, artistLabel, albumLabel, titleLabel, coverContainer])
        baseConstraints(views: [seek, artistLabel, albumLabel, titleLabel, coverContainer])
        initSeek()
        initLabels()
        initCover()
    }
    
    func initSeek() {
        // only triggers valueChanged when dragging has ended
        seek.isContinuous = false
        seek.addTarget(self, action: .seekChanged, for: .valueChanged)
        seek.snp.makeConstraints { make in
            make.top.equalTo(positionLabel.snp.bottom).offset(6)
            make.top.equalTo(durationLabel.snp.bottom).offset(6)
            make.bottom.equalToSuperview().inset(16)
        }
        positionLabel.textAlignment = .left
        positionLabel.snp.makeConstraints { make in
            make.leadingMargin.equalToSuperview()
            make.top.equalTo(artistLabel.snp.bottom).offset(8)
            make.trailing.equalTo(durationLabel.snp.leading)
            make.width.equalTo(durationLabel)
        }
        durationLabel.textAlignment = .right
        durationLabel.snp.makeConstraints { make in
            make.trailingMargin.equalToSuperview()
            make.top.equalTo(artistLabel.snp.bottom).offset(8)
        }
    }
    
    func initLabels() {
        centered(labels: [titleLabel, albumLabel, artistLabel])
        titleLabel.setContentCompressionResistancePriority(.required, for: .vertical)
        titleLabel.font = UIFont.systemFont(ofSize: 28)
        titleLabel.snp.makeConstraints { make in
            make.top.equalTo(coverContainer.snp.bottom).offset(16)
        }
        albumLabel.setContentCompressionResistancePriority(.required, for: .vertical)
        albumLabel.font = UIFont.systemFont(ofSize: 17)
        albumLabel.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(8)
        }
        artistLabel.font = UIFont.systemFont(ofSize: 17)
        artistLabel.setContentCompressionResistancePriority(.required, for: .vertical)
        artistLabel.snp.makeConstraints { make in
            make.top.equalTo(albumLabel.snp.bottom).offset(8)
        }
    }
    
    func initCover() {
        coverContainer.snp.makeConstraints { make in
            make.top.equalTo(self.view.snp.topMargin).offset(8)
            make.bottom.equalTo(titleLabel.snp.top).offset(-16)
            make.leadingMargin.trailingMargin.equalToSuperview()
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
        image.draw(in: CGRect(origin: CGPoint(x: 0, y: 0), size: CGSize(width: newSize.width, height: newSize.height)))
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
    
    override func updateNoMedia() {
        Util.onUiThread {
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
        let _ = CoverService.sharedInstance.cover(track.artist, album: track.album).subscribe { (result) in
            var image = CoverService.defaultCover
            // the track may have changed between the time the cover was requested and received
            if let imageResult = result.image, self.player.current().track?.title == track.title {
                image = imageResult
            }
            if let image = image {
                Util.onUiThread {
                    // self.log.info("Setting cover of \(image) for \(track.title)")
                    self.coverImage.image = image
                }
            } else {
                self.log.warn("No image. This is most likely an error.")
            }
        } onFailure: { (err) in
            self.log.error("Failed to update cover for \(track.artist) - \(track.album).")
        } onDisposed: {
            ()
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
//        updatePlayPause(state == .Playing)
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
    
    @objc func sliderChanged(_ sender: AnyObject) {
        let seekValue = seek.value
        // TODO throttle
        if let pos = seekValue.seconds {
            _ = limitChecked {
                self.player.seek(pos)
            }
        } else {
            log.info("Unable to convert value to Duration: \(seekValue)")
        }
    }
}

extension UIButton {
    func setFontAwesomeTitle(_ fontAwesomeName: String) {
        let buttonText = String.fontAwesomeIconStringForIconIdentifier(fontAwesomeName)
        self.setTitle(buttonText, for: UIControl.State())
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
        let fontDescriptorFeatureSettings = [[UIFontDescriptor.FeatureKey.featureIdentifier: kNumberSpacingType, UIFontDescriptor.FeatureKey.typeIdentifier: kMonospacedNumbersSelector]]
        let fontDescriptorAttributes = [UIFontDescriptor.AttributeName.featureSettings: fontDescriptorFeatureSettings]
        let fontDescriptor = self.addingAttributes(fontDescriptorAttributes)
        return fontDescriptor
    }
    
}
