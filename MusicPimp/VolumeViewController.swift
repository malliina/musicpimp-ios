import Foundation
import RxSwift

extension Selector {
  fileprivate static let volumeChanged = #selector(VolumeViewController.userDidChangeVolume(_:))
  fileprivate static let cancelClicked = #selector(VolumeViewController.backClicked(_:))
}

class VolumeViewController: PimpViewController {
  let lowVolumeButton = UIButton()
  let highVolumeButton = UIButton()

  let volumeSlider = UISlider()

  var appearedBag = DisposeBag()

  var player: PlayerType { PlayerManager.sharedInstance.active }

  override func viewDidLoad() {
    super.viewDidLoad()
    navigationItem.title = "SET VOLUME"
    navigationItem.rightBarButtonItem = UIBarButtonItem(
      barButtonSystemItem: .done, target: self, action: .cancelClicked)
    initUI()
    updateVolume()
  }

  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
    updateVolume()
    listenWhenAppeared(player)
  }

  func initUI() {
    addSubviews(views: [lowVolumeButton, volumeSlider, highVolumeButton])
    installFaImage("fa-volume-down", button: lowVolumeButton)
    lowVolumeButton.snp.makeConstraints { (make) in
      make.leadingMargin.equalToSuperview()
      make.centerY.equalToSuperview()
    }
    volumeSlider.addTarget(self, action: .volumeChanged, for: .valueChanged)
    volumeSlider.snp.makeConstraints { (make) in
      make.leading.equalTo(lowVolumeButton.snp.trailing).offset(8)
      make.trailing.equalTo(highVolumeButton.snp.leading).offset(-8)
      make.centerY.equalToSuperview()
    }
    installFaImage("fa-volume-up", button: highVolumeButton)
    highVolumeButton.snp.makeConstraints { (make) in
      make.trailingMargin.equalToSuperview()
      make.centerY.equalToSuperview()
    }
  }

  func updateVolume() {
    volumeSlider.value = sliderValue(player.current().volume)
  }

  override func viewDidDisappear(_ animated: Bool) {
    super.viewDidDisappear(animated)
    unlistenWhenDisappeared()
  }

  func installFaImage(_ name: String, button: UIButton) {
    button.setTitle("", for: UIControl.State())
    button.setImage(faImage(name), for: UIControl.State())
  }

  func faImage(_ name: String) -> UIImage {
    UIImage(
      icon: name, backgroundColor: UIColor.clear, iconColor: PimpColors.shared.tintColor,
      fontSize: 28)
  }

  @objc func userDidChangeVolume(_ sender: UISlider) {
    let percent = sender.value / (sender.maximumValue - sender.minimumValue)
    let volume = VolumeValue(volume: Int(100.0 * percent))
    _ = player.volume(volume)
  }

  @objc func backClicked(_ sender: UIBarButtonItem) {
    dismiss(animated: true, completion: nil)
  }

  fileprivate func onVolumeChanged(_ volume: VolumeValue) {
    let value = sliderValue(volume)
    Util.onUiThread {
      self.volumeSlider.value = value
    }
  }

  func sliderValue(_ volume: VolumeValue) -> Float {
    volume.toFloat() * (volumeSlider.maximumValue - volumeSlider.minimumValue)
  }

  fileprivate func listenWhenAppeared(_ targetPlayer: PlayerType) {
    unlistenWhenDisappeared()
    targetPlayer.volumeEvent.subscribe(onNext: { (vol) in
      self.onVolumeChanged(vol)
    }).disposed(by: appearedBag)
  }

  fileprivate func unlistenWhenDisappeared() {
    appearedBag = DisposeBag()
  }
}
