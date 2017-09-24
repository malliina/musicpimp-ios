//
//  MostPopularList.swift
//  MusicPimp
//
//  Created by Michael Skogberg on 24/09/2017.
//  Copyright © 2017 Skogberg Labs. All rights reserved.
//

import Foundation

class MostPopularList: TopListController<PopularEntry> {
    override var header: String { return "Most Popular" }
    override var emptyMessage: String { get { return "No popular tracks." } }
    override var failedToLoadMessage: String { return "Failed to load popular tracks." }
    
    override func decorate(cell: SnapMainSubCell, track: PopularEntry) {
        decorateTwoLines(cell, first: track.track.title, second: "\(track.playbackCount) plays")
    }
    
    override func refresh() {
        entries = []
        renderTable("Loading popular tracks...")
        library.popular(0, until: itemsPerLoad, onError: onTopError, f: onTopLoaded)
    }
    
    override func loadMore() {
        let oldSize = entries.count
        library.popular(oldSize, until: oldSize + itemsPerLoad, onError: onTopError) { content in
            self.onMoreResults(oldSize, results: content)
        }
    }
}
