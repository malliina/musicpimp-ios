//
//  MostRecentList.swift
//  MusicPimp
//
//  Created by Michael Skogberg on 24/09/2017.
//  Copyright © 2017 Skogberg Labs. All rights reserved.
//

import Foundation
import RxSwift

class MostRecentList: TopListController<RecentEntry> {
    let MostRecentCellKey = "MostRecentCell"
    override var header: String { return "Most Recent" }
    override var emptyMessage: String { get { return "No recent tracks." } }
    override var failedToLoadMessage: String { return "Failed to load recent tracks." }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.tableView?.register(MostRecentCell.self, forCellReuseIdentifier: MostRecentCellKey)
    }
    
    override func cellFor(track: RecentEntry, indexPath: IndexPath) -> UITableViewCell {
        let cell: MostRecentCell = loadCell(MostRecentCellKey, index: indexPath)
        decorate(cell: cell, track: track)
        cell.accessoryDelegate = self
        return cell
    }
    
    func decorate(cell: MostRecentCell, track: RecentEntry) {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        formatter.doesRelativeDateFormatting = true
        let formattedDate = formatter.string(from: track.when)
        decorateTwoLines(cell, main: track.track.title, subLeft: track.track.artist, subRight: formattedDate)
    }
    
    override func refresh() {
        entries = []
        renderTable("Loading recent tracks...")
        library.recent(0, until: itemsPerLoad).subscribe { (event) in
            switch event {
            case .next(let rs): self.onTopLoaded(rs)
            case .error(let err): self.onTopError(err)
            case .completed: ()
            }
        }.disposed(by: bag)
    }
    
    override func loadMore() {
        let oldSize = entries.count
        library.recent(oldSize, until: oldSize + itemsPerLoad).subscribe { (event) in
            switch event {
            case .next(let rs): self.onMoreResults(oldSize, results: rs)
            case .error(let err): self.onTopError(err)
            case .completed: ()
            }
        }.disposed(by: bag)
    }
}
