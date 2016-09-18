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
    
    fileprivate var appearedListeners: [Disposable] = []
    
    var player: PlayerType { get { return PlayerManager.sharedInstance.active } }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        installFaImage("fa-volume-down", button: lowVolumeButton)
        installFaImage("fa-volume-up", button: highVolumeButton)
        updateVolume()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        updateVolume()
        listenWhenAppeared(player)
    }
    
    func updateVolume() {
        volumeSlider.value = sliderValue(player.current().volume)
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        unlistenWhenDisappeared()
    }
    
    func installFaImage(_ name: String, button: UIButton) {
        button.setTitle("", for: UIControlState())
//        button.titleLabel?.text = ""
        button.setImage(faImage(name), for: UIControlState())
    }
    
    func faImage(_ name: String) -> UIImage {
        return UIImage(icon: name, backgroundColor: UIColor.clear, iconColor: UIColor.blue, fontSize: 28)
    }
    
    @IBAction func userDidChangeVolume(_ sender: UISlider) {
        let percent = sender.value / (sender.maximumValue - sender.minimumValue)
        let volume = VolumeValue(volume: Int(100.0 * percent))
        player.volume(volume)
    }
    
    @IBAction func backClicked(_ sender: UIBarButtonItem) {
        dismiss(animated: true, completion: nil)
    }
    
    fileprivate func onVolumeChanged(_ volume: VolumeValue) {
        let value = sliderValue(volume)
        Util.onUiThread {
            self.volumeSlider.value = value
        }
    }
    
    func sliderValue(_ volume: VolumeValue) -> Float {
        return volume.toFloat() * (volumeSlider.maximumValue - volumeSlider.minimumValue)
    }
    
    fileprivate func listenWhenAppeared(_ targetPlayer: PlayerType) {
        unlistenWhenDisappeared()
        let listener = targetPlayer.volumeEvent.addHandler(self, handler: { (pc) -> (VolumeValue) -> () in
            pc.onVolumeChanged
        })
        appearedListeners = [listener]
    }
    
    fileprivate func unlistenWhenDisappeared() {
        for listener in appearedListeners {
            listener.dispose()
        }
        appearedListeners = []
    }

}
