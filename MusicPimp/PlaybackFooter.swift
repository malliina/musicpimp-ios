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
    
    override func awakeFromNib() {
        super.awakeFromNib()
        self.backgroundColor = PimpColors.background
        self.contentView?.backgroundColor = PimpColors.background
        prevButton.setFontAwesomeTitle("fa-step-backward")
        playPauseButton.setFontAwesomeTitle("fa-pause")
        nextButton.setFontAwesomeTitle("fa-step-forward")
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
