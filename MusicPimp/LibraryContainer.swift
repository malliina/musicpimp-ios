import Foundation

class LibraryContainer: PlaybackContainer, LibraryDelegate {
  private let log = LoggerFactory.shared.vc(LibraryContainer.self)

  let libraryListener = LibraryListener.library

  convenience init() {
    self.init(folder: nil)
  }

  convenience init(folder: Folder?) {
    let library = LibraryController()
    if let folder = folder {
      library.selected = folder
    }
    self.init(title: folder?.title.uppercased() ?? "MUSIC", child: library, persistentFooter: false)
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    libraryListener.delegate = self
    libraryListener.subscribe()
  }

  override func willMove(toParent parent: UIViewController?) {
    super.willMove(toParent: parent)
    // https://stackoverflow.com/a/14155394
    let willPop = parent == nil
    if willPop {
      guard let library = child as? LibraryController else { return }
      library.stopListening()
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
      if let root = navCtrl.viewControllers.headOption() as? LibraryContainer,
        let lvc = root.child as? LibraryController
      {
        log.info("Reloading \(lvc) \(lvc.selected?.title ?? "no selection") on appear")
        lvc.reloadDataOnAppear = true
      } else {
        log.info("No reload")
      }
    } else {
      if let lvc = child as? LibraryController {
        lvc.reloadDataOnAppear = true
        children.forEach { c in
          log.info("Child \(c)")
        }
        log.info("No navigation controller, reloading child \(child) \(lvc.selected?.title ?? "no selection") on appear.")
      } else {
        log.warn("No navigation controller, and no child library controller.")
      }
    }
  }
}
