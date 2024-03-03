import Foundation

class LibraryContainer: PlaybackContainer, LibraryDelegate {
  private let log = LoggerFactory.shared.vc(LibraryContainer.self)

  convenience init() {
    self.init(folder: nil)
  }

  convenience init(folder: Folder?) {
    let library = LibraryController()
    if let folder = folder {
      library.selected = folder
    }
    self.init(title: folder?.title.uppercased() ?? "MUSIC", child: library, persistentFooter: false)
    if folder == nil {
      let listener = LibraryListener.library
      listener.delegate = self
      listener.subscribe()
    }
  }

  override func willMove(toParent parent: UIViewController?) {
    super.willMove(toParent: parent)
    // https://stackoverflow.com/a/14155394
    let willPop = parent == nil
    if willPop {
      guard let library = child as? LibraryController else { return }
      //      library.stopListening()
      library.stopUpdates()
    }
  }

  func onLibraryUpdated(to newLibrary: LibraryType) async {
    log.info("Library updated to \(newLibrary.id), popping...")
    await pop()
  }

  @MainActor
  private func pop(_ animated: Bool = false) async {
    if let navCtrl = navigationController {
      navCtrl.popToRootViewController(animated: animated)
    }
  }
}
