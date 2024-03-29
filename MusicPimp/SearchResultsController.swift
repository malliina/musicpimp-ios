import Foundation

class SearchResultsController: BaseMusicController {
  let log = LoggerFactory.shared.vc(SearchResultsController.self)
  var results: [Track] = []

  override var musicItems: [MusicItem] { return results }

  fileprivate var latestSearchTerm: String? = nil

  override func viewDidLoad() {
    super.viewDidLoad()
    // WTF? This is needed to close the gap between the search bar and search results
    edgesForExtendedLayout = UIRectEdge()
  }

  override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath)
    -> UITableViewCell
  {
    let track = results[(indexPath as NSIndexPath).row]
    let cell = trackCell(track, index: indexPath)
    cell?.progress.isHidden = true
    return cell!
  }

  func search(_ term: String) async {
    let characters = term.count
    if characters >= 2 {
      latestSearchTerm = term
      withMessage("Searching for \(term)...") {
        self.results = []
      }
      do {
        let results = try await library.search(term)
        // only updates the UI if the response represents the latest search
        if self.latestSearchTerm == term {
          self.withMessage(results.isEmpty ? "No results for \(term)" : nil) {
            self.results = results
          }
        }
      } catch {
        onSearchFailure(term, error: error)
      }
    } else {
      withMessage(characters == 1 ? "Input one more character..." : "Input two or more characters")
      {
        self.results = []
      }
    }
  }

  func onSearchFailure(_ term: String, error: Error) {
    log.info("Search for \(term) failed. \(error.message)")
    if term == latestSearchTerm {
      self.withMessage("Search of \(term) failed") {}
    }
  }
}

extension Error {
  var message: String { Util.message(error: self) }
}
