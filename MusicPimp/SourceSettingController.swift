import Foundation
import UIKit

class SourceSettingController: EndpointSelectController, LibraryEndpointDelegate {
  let manager = LibraryManager.sharedInstance

  let listener = EndpointsListener()

  override func viewDidLoad() {
    super.viewDidLoad()
    navigationItem.title = "SOURCES"
    listener.libraries = self
  }

  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    listener.subscribe()
  }

  override func viewDidDisappear(_ animated: Bool) {
    super.viewDidDisappear(animated)
    listener.unsubscribe()
  }

  func onLibraryUpdated(to newLibrary: Endpoint) {
    updateSelected(newLibrary)
    renderTable()
  }

  override func use(endpoint: Endpoint) {
    let _ = manager.use(endpoint: endpoint)
  }

  override func loadActive() -> Endpoint {
    manager.loadActive()
  }
}
