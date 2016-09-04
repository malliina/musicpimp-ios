//
//  VolumeViewController.swift
//  MusicPimp
//
//  Created by Michael Skogberg on 10/01/16.
//  Copyright © 2016 Skogberg Labs. All rights reserved.
//

import Foundation

class VolumeViewController: PimpViewController {
    
    @IBOutlet var lowVolumeButton: UIButton!
    @IBOutlet var highVolumeButton: UIButton!
    
    @IBOutlet var volumeSlider: UISlider!
    
    private var appearedListeners: [Disposable] = []
    
    var player: PlayerType { get { return PlayerManager.sharedInstance.active } }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        installFaImage("fa-volume-down", button: lowVolumeButton)
        installFaImage("fa-volume-up", button: highVolumeButton)
        updateVolume()
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        updateVolume()
        listenWhenAppeared(player)
    }
    
    func updateVolume() {
        volumeSlider.value = sliderValue(player.current().volume)
    }
    
    override func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(animated)
        unlistenWhenDisappeared()
    }
    
    func installFaImage(name: String, button: UIButton) {
        button.setTitle("", forState: .Normal)
//        button.titleLabel?.text = ""
        button.setImage(faImage(name), forState: UIControlState.Normal)
    }
    
    func faImage(name: String) -> UIImage {
        return UIImage(icon: name, backgroundColor: UIColor.clearColor(), iconColor: UIColor.blueColor(), fontSize: 28)
    }
    
    @IBAction func userDidChangeVolume(sender: UISlider) {
        let percent = sender.value / (sender.maximumValue - sender.minimumValue)
        let volume = VolumeValue(volume: Int(100.0 * percent))
        player.volume(volume)
    }
    
    @IBAction func backClicked(sender: UIBarButtonItem) {
        dismissViewControllerAnimated(true, completion: nil)
    }
    
    private func onVolumeChanged(volume: VolumeValue) {
        let value = sliderValue(volume)
        Util.onUiThread {
            self.volumeSlider.value = value
        }
    }
    
    func sliderValue(volume: VolumeValue) -> Float {
        return volume.toFloat() * (volumeSlider.maximumValue - volumeSlider.minimumValue)
    }
    
    private func listenWhenAppeared(targetPlayer: PlayerType) {
        unlistenWhenDisappeared()
        let listener = targetPlayer.volumeEvent.addHandler(self, handler: { (pc) -> VolumeValue -> () in
            pc.onVolumeChanged
        })
        appearedListeners = [listener]
    }
    
    private func unlistenWhenDisappeared() {
        for listener in appearedListeners {
            listener.dispose()
        }
        appearedListeners = []
    }

}
