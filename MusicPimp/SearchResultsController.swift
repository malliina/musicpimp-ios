//
//  SearchResultsController.swift
//  MusicPimp
//
//  Created by Michael Skogberg on 10/10/15.
//  Copyright © 2015 Skogberg Labs. All rights reserved.
//

import Foundation

class SearchResultsController: BaseMusicController {
    let log = LoggerFactory.vc("SearchResultsController")
    var results: [Track] = []
    
    override var musicItems: [MusicItem] { return results }
    
    fileprivate var latestSearchTerm: String? = nil
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // WTF? This is needed to close the gap between the search bar and search results
        edgesForExtendedLayout = UIRectEdge()
    }
        
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let track = results[(indexPath as NSIndexPath).row]
        let cell = trackCell(track, index: indexPath)
        cell?.progress.isHidden = true
        return cell!
    }
    
    func search(_ term: String) {
        let characters = term.count
        if characters >= 2 {
            latestSearchTerm = term
            withMessage("Searching for \(term)...") {
                self.results = []
            }
            library.search(term, onError: { self.onSearchFailure(term, error: $0) }) { (results) -> Void in
                // only updates the UI if the response represents the latest search
                if self.latestSearchTerm == term {
                    self.withMessage(results.isEmpty ? "No results for \(term)" : nil) {
                        self.results = results
                    }
                }
            }
        } else {
            withMessage(characters == 1 ? "Input one more character..." : "Input two or more characters") {
                self.results = []
            }
        }
    }
    
    func onSearchFailure(_ term: String, error: PimpError) {
        log.info("Search for \(term) failed. \(error.message)")
        if term == latestSearchTerm {
            self.withMessage("Search of \(term) failed") { }
        }
    }
}
