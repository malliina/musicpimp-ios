import Foundation
import SnapKit

class ContainerParent: ListeningController, PlaybackDelegate {
  private let log = LoggerFactory.shared.vc(ContainerParent.self)
  static var isIpad: Bool {
    let traits = UIScreen.main.traitCollection
    return traits.horizontalSizeClass == .regular && traits.verticalSizeClass == .regular
  }
  static var defaultFooterHeight: CGFloat { ContainerParent.isIpad ? 66 : 44 }
  let playbackFooter: SnapPlaybackFooter
  var currentFooterHeight: CGFloat { return 0 }

  let playbackFooterHeightValue: CGFloat
  var preferredPlaybackFooterHeight: CGFloat {
    let state = player.current().state
    return state == .Playing || (ContainerParent.isIpad && state != .NoMedia)
      ? playbackFooterHeightValue : 0
  }
  private var currentHeight: CGFloat = 0

  convenience init(persistent: Bool) {
    self.init(footerHeight: ContainerParent.defaultFooterHeight, persistent: persistent)
  }

  init(footerHeight: CGFloat, persistent: Bool) {
    self.playbackFooterHeightValue = footerHeight
    self.playbackFooter = SnapPlaybackFooter(persistent: persistent)
    super.init(nibName: nil, bundle: nil)
  }

  required init?(coder aDecoder: NSCoder) {
    self.playbackFooterHeightValue = ContainerParent.defaultFooterHeight
    self.playbackFooter = SnapPlaybackFooter(persistent: false)
    super.init(coder: aDecoder)
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    initPlaybackFooter()
    self.automaticallyAdjustsScrollViewInsets = false
  }

  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    updateFooterState()
  }

  /// https://developer.apple.com/library/content/featuredarticles/ViewControllerPGforiPhoneOS/ImplementingaContainerViewController.html#//apple_ref/doc/uid/TP40007457-CH11-SW12
  func initChild(_ child: UIViewController) {
    addChild(child)
    // ?
    child.view.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(child.view)
    child.didMove(toParent: self)
  }

  func initPlaybackFooter() {
    playbackFooter.delegate = self
    view.addSubview(playbackFooter)
    playbackFooter.snp.makeConstraints { make in
      make.leading.trailing.bottom.equalToSuperview()
      make.height.equalTo(currentFooterHeight)
      currentHeight = currentFooterHeight
    }
  }

  fileprivate func updateFooterState() {
    updateFooter(state: player.current().state, animated: false)
  }

  override func onStateChanged(_ state: PlaybackState) {
    updateFooter(state: state, animated: true)
  }

  func updateFooter(state: PlaybackState, animated: Bool) {
    Util.onUiThread {
      // Uses delays so that the footer does not flicker between transient track changes
      let buttonDelay: Double = animated ? 0.1 : 0
      DispatchQueue.main.asyncAfter(deadline: .now() + buttonDelay) {
        self.playbackFooter.updatePlayPause(isPlaying: self.player.current().state == .Playing)
      }
      let footerDelay: Double = animated ? 1.0 : 0
      if animated {
        DispatchQueue.main.asyncAfter(deadline: .now() + footerDelay) {
          let isPermanent = state == self.player.current().state
          if isPermanent {
            self.view.setNeedsUpdateConstraints()
            if animated {
              UIView.animate(withDuration: 0.25) {
                self.view.layoutIfNeeded()
              }
            }
          }
        }
      } else {
        self.view.setNeedsUpdateConstraints()
      }
    }
  }

  override func updateViewConstraints() {
    let footerHeight = preferredPlaybackFooterHeight
    if footerHeight != currentHeight {
      currentHeight = footerHeight
      self.playbackFooter.snp.updateConstraints { make in
        make.height.equalTo(currentHeight)
      }
    }
    super.updateViewConstraints()
  }

  func onPrev() {
    _ = player.prev()
  }

  func onPlayPause() {
    self.playOrPause()
  }

  func onNext() {
    _ = player.next()
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
}
