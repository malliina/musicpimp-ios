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
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        if musicItems.count == 0 {
            let cell = tableView.dequeueReusableCellWithIdentifier(BaseMusicController.feedbackIdentifier, forIndexPath: indexPath)
            var noResultsMessage = "No results"
            if let term = latestSearchTerm {
                noResultsMessage = "No results for \(term)"
            }
            let statusMessage = feedbackMessage ?? noResultsMessage
            cell.textLabel?.text = statusMessage
            return cell
        } else {
            let track = results[indexPath.row]	
            let cell = trackCell(track)
            cell?.progressView.hidden = true
            return cell!
        }
    }
    
    func search(term: String) {
        let characters = term.characters.count
        if characters >= 2 {
            latestSearchTerm = term
            let message = "Searching for \(term)..."
            info(message)
            self.feedbackMessage = message
            self.renderTable()
            library.search(term, onError: { self.onSearchFailure(term, error: $0) }) { (results) -> Void in
                Log.info("Got \(results.count) results for \(term)")
                // only updates the UI if the response represents the latest search
                if self.latestSearchTerm == term {
                    self.feedbackMessage = nil
                    self.results = results
                    self.renderTable()
                }
            }
        } else {
            results = []
            if characters == 1 {
                feedbackMessage = "Input one more character..."
            } else {
                feedbackMessage = "Input two or more characters"
            }
            self.renderTable()
        }
    }
    
    func onSearchFailure(term: String, error: PimpError) {
        let message = PimpErrorUtil.stringify(error)
        info("Search of \(term) failed. \(message)")
        if term == latestSearchTerm {
            self.feedbackMessage = "Search of \(term) failed"
            self.renderTable()
        }
    }
}
