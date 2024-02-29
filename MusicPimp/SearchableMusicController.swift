import Foundation

class SearchableMusicController: BaseMusicController {
  /// Restoration state for UISearchController
  var restoredState = SearchControllerRestorableState()
  var resultsController: SearchResultsController!
  var searchController: UISearchController!
  fileprivate var latestSearchString: String? = nil

  override func viewDidLoad() {
    super.viewDidLoad()
    initSearch()
  }

  func itemAt(_ tableView: UITableView, indexPath: IndexPath) -> MusicItem? {
    let items = tableView == self.tableView ? musicItems : resultsController.musicItems
    let row = indexPath.row
    if items.count > row {
      return items[row]
    } else {
      return nil
    }
  }
}

extension SearchableMusicController: UISearchBarDelegate, UISearchControllerDelegate,
  UISearchResultsUpdating
{
  /// State restoration values.
  enum RestorationKeys: String {
    case viewControllerTitle
    case searchControllerIsActive
    case searchBarText
    case searchBarIsFirstResponder
  }

  struct SearchControllerRestorableState {
    var wasActive = false
    var wasFirstResponder = false
  }

  fileprivate func initSearch() {
    resultsController = SearchResultsController()
    resultsController.tableView.delegate = self
    searchController = UISearchController(searchResultsController: resultsController)
    searchController.searchResultsUpdater = self
    let searchBar = searchController.searchBar
    searchBar.sizeToFit()
    //        searchBar.searchBarStyle = UISearchBarStyle.minimal
    searchBar.barStyle = UIBarStyle.default
    searchBar.barTintColor = UIColor.clear
    searchBar.tintColor = UIColor.red
    if #available(iOS 13.0, *) {
      searchBar.searchTextField.textColor = colors.text
    } else {
      // I think the color is OK before iOS 13
    }
    searchBar.isTranslucent = true
    searchBar.placeholder = "Search track or artist"
    searchController.delegate = self
    searchController.dimsBackgroundDuringPresentation = false
    searchBar.delegate = self
    definesPresentationContext = false
    //        searchController.edgesForExtendedLayout = UIRectEdge.None
  }

  fileprivate func restoreSearch() {
    // Restore the searchController's active state.
    if restoredState.wasActive {
      searchController.isActive = restoredState.wasActive
      restoredState.wasActive = false

      if restoredState.wasFirstResponder {
        searchController.searchBar.becomeFirstResponder()
        restoredState.wasFirstResponder = false
      }
    }
  }

  func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
    searchBar.resignFirstResponder()
  }

  func presentSearchController(_ searchController: UISearchController) {
  }

  func willPresentSearchController(_ searchController: UISearchController) {
  }

  func didPresentSearchController(_ searchController: UISearchController) {
  }

  func willDismissSearchController(_ searchController: UISearchController) {
  }

  func didDismissSearchController(_ searchController: UISearchController) {
  }

  func updateSearchResults(for searchController: UISearchController) {
    // Strips out all the leading and trailing spaces.
    let whitespaceCharacterSet = CharacterSet.whitespaces
    let strippedString =
      searchController.searchBar.text?.trimmingCharacters(in: whitespaceCharacterSet) ?? ""
    Task {
      await resultsController.search(strippedString)
    }
  }

  override func encodeRestorableState(with coder: NSCoder) {
    super.encodeRestorableState(with: coder)

    // Encode the view state so it can be restored later.

    // Encode the title.
    coder.encode(navigationItem.title!, forKey: RestorationKeys.viewControllerTitle.rawValue)

    // Encode the search controller's active state.
    coder.encode(
      searchController.isActive, forKey: RestorationKeys.searchControllerIsActive.rawValue)

    // Encode the first responser status.
    coder.encode(
      searchController.searchBar.isFirstResponder,
      forKey: RestorationKeys.searchBarIsFirstResponder.rawValue)

    // Encode the search bar text.
    coder.encode(searchController.searchBar.text, forKey: RestorationKeys.searchBarText.rawValue)
  }

  override func decodeRestorableState(with coder: NSCoder) {
    super.decodeRestorableState(with: coder)

    // Restore the title.
    guard
      let decodedTitle = coder.decodeObject(forKey: RestorationKeys.viewControllerTitle.rawValue)
        as? String
    else {
      fatalError("A title did not exist. In your app, handle this gracefully.")
    }
    title = decodedTitle

    // Restore the active state:
    // We can't make the searchController active here since it's not part of the view
    // hierarchy yet, instead we do it in viewWillAppear.
    //
    restoredState.wasActive = coder.decodeBool(
      forKey: RestorationKeys.searchControllerIsActive.rawValue)

    // Restore the first responder status:
    // Like above, we can't make the searchController first responder here since it's not part of the view
    // hierarchy yet, instead we do it in viewWillAppear.
    //
    restoredState.wasFirstResponder = coder.decodeBool(
      forKey: RestorationKeys.searchBarIsFirstResponder.rawValue)

    // Restore the text in the search field.
    searchController.searchBar.text =
      coder.decodeObject(forKey: RestorationKeys.searchBarText.rawValue) as? String
  }
}
