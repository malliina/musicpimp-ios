//
//  PlaybackFooter.swift
//  MusicPimp
//
//  Created by Michael Skogberg on 22/04/2017.
//  Copyright © 2017 Skogberg Labs. All rights reserved.
//

import Foundation

protocol PlaybackDelegate {
    func onPlayPause()
    func onPrev()
    func onNext()
}

// http://stackoverflow.com/a/37668821
class PlaybackFooter: UIView {
    @IBOutlet var prevButton: UIButton!
    @IBOutlet var playPauseButton: UIButton!
    @IBOutlet var nextButton: UIButton!

    var delegate: PlaybackDelegate? = nil
   
    @IBAction func prevClicked(_ sender: UIButton) {
        delegate?.onPrev()
    }
    @IBAction func playPauseClicked(_ sender: UIButton) {
        delegate?.onPlayPause()
    }
    @IBAction func nextClicked(_ sender: UIButton) {
        delegate?.onNext()
    }
    
    var contentView : UIView?
    
    let playIconName = "fa-play"
    let pauseIconName = "fa-pause"
    
    func updatePlayPause(isPlaying: Bool) {
        let iconName = isPlaying ? pauseIconName : playIconName
        playPauseButton.setFontAwesomeTitle(iconName)
    }
    
    func setSizes(prev: CGFloat, playPause: CGFloat, next: CGFloat) {
        setAwesomeSize(button: prevButton, size: prev)
        setAwesomeSize(button: playPauseButton, size: playPause)
        setAwesomeSize(button: nextButton, size: next)
    }
    
    private func setAwesomeSize(button: UIButton, size: CGFloat) {
        button.titleLabel?.font = UIFont(awesomeFontOfSize: size)
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        self.backgroundColor = PimpColors.background
        self.contentView?.backgroundColor = PimpColors.background
        prevButton.setFontAwesomeTitle("fa-step-backward")
        updatePlayPause(isPlaying: false)
        nextButton.setFontAwesomeTitle("fa-step-forward")
        initColor(buttons: [prevButton, playPauseButton, nextButton])
    }
    
    private func initColor(buttons: [UIButton]) {
        buttons.forEach { (button) in
            button.titleLabel?.textColor = PimpColors.tintColor
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        xibSetup()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        xibSetup()
    }
    
    func xibSetup() {
        contentView = loadViewFromNib()
        
        // use bounds not frame or it'll be offset
        contentView!.frame = bounds
        
        // Make the view stretch with containing view
        contentView!.autoresizingMask = [UIViewAutoresizing.flexibleWidth, UIViewAutoresizing.flexibleHeight]
        
        // Adding custom subview on top of our view (over any custom drawing > see note below)
        addSubview(contentView!)
    }
    
    func loadViewFromNib() -> UIView! {
        
        let bundle = Bundle(for: type(of: self))
        let nib = UINib(nibName: String(describing: type(of: self)), bundle: bundle)
        let view = nib.instantiate(withOwner: self, options: nil)[0] as! UIView
        
        return view
    }
}
