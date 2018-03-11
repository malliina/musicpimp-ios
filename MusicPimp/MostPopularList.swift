//
//  MostPopularList.swift
//  MusicPimp
//
//  Created by Michael Skogberg on 24/09/2017.
//  Copyright © 2017 Skogberg Labs. All rights reserved.
//

import Foundation

class MostPopularList: TopListController<PopularEntry> {
    let MostPopularCellKey = "MostPopularCell"
    override var header: String { return "Most Popular" }
    override var emptyMessage: String { get { return "No popular tracks." } }
    override var failedToLoadMessage: String { return "Failed to load popular tracks." }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.tableView?.register(MostPopularCell.self, forCellReuseIdentifier: MostPopularCellKey)
    }
    
    override func cellFor(track: PopularEntry, indexPath: IndexPath) -> UITableViewCell {
        let cell: MostPopularCell = loadCell(MostPopularCellKey, index: indexPath)
        decorateTwoLines(cell, main: track.track.title, subLeft: track.track.artist, subRight: "\(track.playbackCount) plays")
        cell.accessoryDelegate = self
        return cell
    }
    
    override func refresh() {
        withMessage("Loading popular tracks...") {
            self.entries = []
        }
        library.popular(0, until: itemsPerLoad, onError: onTopError, f: onTopLoaded)
    }
    
    override func loadMore() {
        let oldSize = entries.count
        library.popular(oldSize, until: oldSize + itemsPerLoad, onError: onTopError) { content in
            self.onMoreResults(oldSize, results: content)
        }
    }
}
