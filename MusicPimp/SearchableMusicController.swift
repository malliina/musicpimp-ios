//
//  SearchableMusicController.swift
//  MusicPimp
//
//  Created by Michael Skogberg on 25/12/15.
//  Copyright © 2015 Skogberg Labs. All rights reserved.
//

import Foundation

class SearchableMusicController: BaseMusicController {
    /// Restoration state for UISearchController
    var restoredState = SearchControllerRestorableState()
    var resultsController: SearchResultsController!
    var searchController: UISearchController!
    private var latestSearchString: String? = nil
    
    override func viewDidLoad() {
        super.viewDidLoad()
        initSearch()
    }
    
    func itemAt(tableView: UITableView, indexPath: NSIndexPath) -> MusicItem? {
        let items = tableView == self.tableView ? musicItems : resultsController.musicItems
        let row = indexPath.row
        if items.count > row {
            return items[row]
        } else {
            return nil
        }
    }
}

extension SearchableMusicController: UISearchBarDelegate, UISearchControllerDelegate, UISearchResultsUpdating {
    /// State restoration values.
    enum RestorationKeys : String {
        case viewControllerTitle
        case searchControllerIsActive
        case searchBarText
        case searchBarIsFirstResponder
    }
    
    struct SearchControllerRestorableState {
        var wasActive = false
        var wasFirstResponder = false
    }
    
    private func initSearch() {
        resultsController = SearchResultsController()
        resultsController.tableView.delegate = self
        searchController = UISearchController(searchResultsController: resultsController)
        searchController.searchResultsUpdater = self
        searchController.searchBar.sizeToFit()
        searchController.searchBar.placeholder = "Search track or artist"
        tableView.tableHeaderView = searchController.searchBar
        searchController.delegate = self
        searchController.dimsBackgroundDuringPresentation = false
        searchController.searchBar.delegate = self
        definesPresentationContext = false
    }
    
    private func restoreSearch() {
        // Restore the searchController's active state.
        if restoredState.wasActive {
            searchController.active = restoredState.wasActive
            restoredState.wasActive = false
            
            if restoredState.wasFirstResponder {
                searchController.searchBar.becomeFirstResponder()
                restoredState.wasFirstResponder = false
            }
        }
    }
    
    func searchBarSearchButtonClicked(searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
    }
    
    func presentSearchController(searchController: UISearchController) {
    }
    
    func willPresentSearchController(searchController: UISearchController) {
    }
    
    func didPresentSearchController(searchController: UISearchController) {
    }
    
    func willDismissSearchController(searchController: UISearchController) {
    }
    
    func didDismissSearchController(searchController: UISearchController) {
    }
    
    func updateSearchResultsForSearchController(searchController: UISearchController) {
        // Strips out all the leading and trailing spaces.
        let whitespaceCharacterSet = NSCharacterSet.whitespaceCharacterSet()
        let strippedString = searchController.searchBar.text?.stringByTrimmingCharactersInSet(whitespaceCharacterSet) ?? ""
        self.resultsController.search(strippedString)
    }
    
    override func encodeRestorableStateWithCoder(coder: NSCoder) {
        super.encodeRestorableStateWithCoder(coder)
        
        // Encode the view state so it can be restored later.
        
        // Encode the title.
        coder.encodeObject(navigationItem.title!, forKey:RestorationKeys.viewControllerTitle.rawValue)
        
        // Encode the search controller's active state.
        coder.encodeBool(searchController.active, forKey:RestorationKeys.searchControllerIsActive.rawValue)
        
        // Encode the first responser status.
        coder.encodeBool(searchController.searchBar.isFirstResponder(), forKey:RestorationKeys.searchBarIsFirstResponder.rawValue)
        
        // Encode the search bar text.
        coder.encodeObject(searchController.searchBar.text, forKey:RestorationKeys.searchBarText.rawValue)
    }
    
    override func decodeRestorableStateWithCoder(coder: NSCoder) {
        super.decodeRestorableStateWithCoder(coder)
        
        // Restore the title.
        guard let decodedTitle = coder.decodeObjectForKey(RestorationKeys.viewControllerTitle.rawValue) as? String else {
            fatalError("A title did not exist. In your app, handle this gracefully.")
        }
        title = decodedTitle
        
        // Restore the active state:
        // We can't make the searchController active here since it's not part of the view
        // hierarchy yet, instead we do it in viewWillAppear.
        //
        restoredState.wasActive = coder.decodeBoolForKey(RestorationKeys.searchControllerIsActive.rawValue)
        
        // Restore the first responder status:
        // Like above, we can't make the searchController first responder here since it's not part of the view
        // hierarchy yet, instead we do it in viewWillAppear.
        //
        restoredState.wasFirstResponder = coder.decodeBoolForKey(RestorationKeys.searchBarIsFirstResponder.rawValue)
        
        // Restore the text in the search field.
        searchController.searchBar.text = coder.decodeObjectForKey(RestorationKeys.searchBarText.rawValue) as? String
    }
}
