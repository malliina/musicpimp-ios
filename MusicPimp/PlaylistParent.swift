import Foundation

extension Selector {
  fileprivate static let scopeChanged = #selector(PlaylistParent.scopeChanged(_:))
}

class PlaylistParent: ContainerParent, LibraryDelegate {
  private let log = LoggerFactory.shared.vc(PlaylistParent.self)
  let scopeSegment = UISegmentedControl(items: ["Popular", "Recent"])
  let table = PlaylistController()
  let libraryListener = LibraryListener.playlists

  override func viewDidLoad() {
    super.viewDidLoad()
    navigationItem.title = "PLAYLISTS"
    // wtf?
    navigationController?.navigationBar.isTranslucent = true
    initUI()
    libraryListener.delegate = self
    libraryListener.subscribe()
  }

  func initUI() {
    initScope(scopeSegment)
    addSubviews(views: [scopeSegment])
    scopeSegment.snp.makeConstraints { make in
      make.top.equalToSuperview().offset(8)
      make.leadingMargin.trailingMargin.equalToSuperview()
    }
    initChild(table)
    table.view.snp.makeConstraints { make in
      make.top.equalTo(scopeSegment.snp.bottom).offset(8)
      make.leading.trailing.equalTo(view)
      make.bottom.equalTo(playbackFooter.snp.top)
    }
  }

  fileprivate func initScope(_ ctrl: UISegmentedControl) {
    ctrl.selectedSegmentIndex = 0
    ctrl.addTarget(self, action: .scopeChanged, for: .valueChanged)
    ctrl.setTitleTextAttributes(
      [NSAttributedString.Key.foregroundColor: PimpColors.shared.tintColor], for: .normal)
    if #available(iOS 13.0, *) {
      ctrl.selectedSegmentTintColor = PimpColors.shared.background
    } else {
      // Fallback on earlier versions
    }
  }

  func onLibraryUpdated(to newLibrary: LibraryType) async {
    await scopeChanged(scopeSegment)
  }

  @objc func scopeChanged(_ ctrl: UISegmentedControl) async {
    let mode = ListMode(rawValue: ctrl.selectedSegmentIndex) ?? .popular
    await table.maybeRefresh(mode)
  }
}
