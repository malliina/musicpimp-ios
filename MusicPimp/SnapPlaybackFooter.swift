//
//  SnapPlaybackFooter.swift
//  MusicPimp
//
//  Created by Michael Skogberg on 01/05/2017.
//  Copyright © 2017 Skogberg Labs. All rights reserved.
//

import Foundation

fileprivate extension Selector {
    static let prevClicked = #selector(SnapPlaybackFooter.onPrevClicked(_:))
    static let playPauseClicked = #selector(SnapPlaybackFooter.onPlayPauseClicked(_:))
    static let nextClicked = #selector(SnapPlaybackFooter.onNextClicked(_:))
}

extension UIButton {
    func addHandler(target: Any?, selector: Selector) {
        addTarget(target, action: selector, for: .touchUpInside)
    }
}

class SnapPlaybackFooter: BaseView {
    let pauseIconName = "fa-pause"
    let playIconName = "fa-play"
    let prevIconName = "fa-step-backward"
    let nextIconName = "fa-step-forward"
    let defaultFontSize: CGFloat = 17
    
    let prevButton = UIButton()
    let playPauseButton = UIButton()
    let nextButton = UIButton()
    
    var delegate: PlaybackDelegate? = nil
    
    override func configureView() {
        self.backgroundColor = PimpColors.shared.background
        ContainerParent.isIpad ? setBigSize() : setSmallSize()
        prevButton.setFontAwesomeTitle(prevIconName)
        playPauseButton.setFontAwesomeTitle(playIconName)
        nextButton.setFontAwesomeTitle(nextIconName)
        initColor(buttons: [prevButton, playPauseButton, nextButton])
        
        addSubviews(views: [prevButton, playPauseButton, nextButton])
        
        prevButton.addHandler(target: self, selector: .prevClicked)
        playPauseButton.addHandler(target: self, selector: .playPauseClicked)
        nextButton.addHandler(target: self, selector: .nextClicked)
        
        prevButton.snp.makeConstraints { make in
            make.leading.top.bottom.equalToSuperview()
        }
        
        playPauseButton.snp.makeConstraints { make in
            make.leading.equalTo(prevButton.snp.trailing)
            make.top.bottom.width.equalTo(prevButton)
        }
        
        nextButton.snp.makeConstraints { make in
            make.leading.equalTo(playPauseButton.snp.trailing)
            make.trailing.equalTo(self.snp.trailing)
            make.top.bottom.width.equalTo(playPauseButton)
        }
    }
    
    @objc func onPrevClicked(_ button: UIButton) {
        delegate?.onPrev()
    }
    
    @objc func onPlayPauseClicked(_ button: UIButton) {
        delegate?.onPlayPause()
    }
    
    @objc func onNextClicked(_ button: UIButton) {
        delegate?.onNext()
    }
    
    func setBigSize() {
        setSizes(prev: 24, playPause: 32, next: 24)
    }
    
    func setSmallSize() {
        setSizes(prev: defaultFontSize, playPause: defaultFontSize, next: defaultFontSize)
    }
    
    func setSizes(prev: CGFloat, playPause: CGFloat, next: CGFloat) {
        setAwesomeSize(button: prevButton, size: prev)
        setAwesomeSize(button: playPauseButton, size: playPause)
        setAwesomeSize(button: nextButton, size: next)
    }
    
    private func setAwesomeSize(button: UIButton, size: CGFloat) {
        button.titleLabel?.font = UIFont(awesomeFontOfSize: size)
    }
    
    func updatePlayPause(isPlaying: Bool) {
        let iconName = isPlaying ? pauseIconName : playIconName
        playPauseButton.setFontAwesomeTitle(iconName)
    }
    
    private func initColor(buttons: [UIButton]) {
        buttons.forEach { button in
            button.setTitleColor(PimpColors.shared.tintColor, for: UIControl.State.normal)
            //button.titleLabel?.textColor = PimpColors.tintColor
        }
    }
}
