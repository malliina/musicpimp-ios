//
//  ContainerParent.swift
//  MusicPimp
//
//  Created by Michael Skogberg on 13/08/16.
//  Copyright © 2016 Skogberg Labs. All rights reserved.
//

import Foundation

class ContainerParent: ListeningController {
    @IBOutlet var prevButton: UIButton!
    @IBOutlet var playButton: UIButton!
    @IBOutlet var nextButton: UIButton!
    
    @IBOutlet var playBottom: NSLayoutConstraint!
    @IBOutlet var nextBottom: NSLayoutConstraint!
    @IBOutlet var prevBottom: NSLayoutConstraint!
    @IBOutlet var nextTop: NSLayoutConstraint!
    @IBOutlet var prevHeight: NSLayoutConstraint!
    @IBOutlet var playHeight: NSLayoutConstraint!
    @IBOutlet var nextHeight: NSLayoutConstraint!
    
    var constraintToggle: ConstraintToggle? = nil
    
    override func viewDidLoad() {
        super.viewDidLoad()
        constraintToggle = ConstraintToggle(constraints: [prevBottom, playBottom, nextBottom, nextTop, prevHeight, playHeight, nextHeight])
        prevButton.setFontAwesomeTitle("fa-step-backward")
        playButton.setFontAwesomeTitle("fa-pause")
        nextButton.setFontAwesomeTitle("fa-step-forward")
        self.automaticallyAdjustsScrollViewInsets = false
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        initFooter()
    }
    
    private func initFooter() {
        onStateChanged(player.current().state)
    }

    override func onStateChanged(state: PlaybackState) {
        let isVisible = state == .Playing
        let toggle = self.constraintToggle
        Util.onUiThread {
            self.playButton.hidden = !isVisible
            self.prevButton.hidden = !isVisible
            self.nextButton.hidden = !isVisible
            if isVisible {
                toggle?.show()
            } else {
                toggle?.hide()
            }
        }
    }
    
    @IBAction func prevClicked(sender: UIButton) {
        player.prev()
    }
    
    @IBAction func playPauseClicked(sender: UIButton) {
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
    
    @IBAction func nextClicked(sender: UIButton) {
        player.next()
    }
    
    func findChild<T>() -> T? {
        let pcs = childViewControllers.flatMapOpt { (vc) -> T? in
            return vc as? T
        }
        return pcs.headOption()
    }
}
