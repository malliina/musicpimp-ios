//
//  SearchResultsController.swift
//  MusicPimp
//
//  Created by Michael Skogberg on 10/10/15.
//  Copyright © 2015 Skogberg Labs. All rights reserved.
//

import Foundation

class SearchResultsController: BaseMusicController {
    var results: [Track] = []
    
    override var musicItems: [MusicItem] { return results }
    
    private var latestSearchTerm: String? = nil
    
    override func viewDidLoad() {
//        self.tableView.contentInset = UIEdgeInsets(top: -64, left: 0, bottom: 0, right: 0)
        super.viewDidLoad()
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let track = results[indexPath.row]
        let cell = trackCell(track, index: indexPath)
        cell?.progressView.hidden = true
        return cell!
    }
    
    func search(term: String) {
        results = []
        let characters = term.characters.count
        if characters >= 2 {
            latestSearchTerm = term
            let message = "Searching for \(term)..."
            info(message)
            self.renderTable(message)
            library.search(term, onError: { self.onSearchFailure(term, error: $0) }) { (results) -> Void in
                Log.info("Got \(results.count) results for \(term)")
                // only updates the UI if the response represents the latest search
                if self.latestSearchTerm == term {
                    let message: String? = results.isEmpty ? "No results for \(term)" : nil
                    self.results = results
                    self.renderTable(message)
                }
            }
        } else {
            let message = characters == 1 ? "Input one more character..." : "Input two or more characters"
            self.renderTable(message)
        }
    }
    
    func onSearchFailure(term: String, error: PimpError) {
        let message = PimpErrorUtil.stringify(error)
        info("Search for \(term) failed. \(message)")
        if term == latestSearchTerm {
            self.renderTable("Search of \(term) failed")
        }
    }
}
