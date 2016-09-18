//
//  FeedbackTable.swift
//  MusicPimp
//
//  Created by Michael Skogberg on 11/01/16.
//  Copyright © 2016 Skogberg Labs. All rights reserved.
//

import Foundation

class FeedbackTable: BaseTableController {
    static let mainAndSubtitleCellKey = "MainAndSubtitleCell"
    static let mainAndSubtitleCellHeight: CGFloat = 65
    static let feedbackIdentifier = "FeedbackCell"

    override func viewDidLoad() {
        super.viewDidLoad()
        self.tableView?.register(UITableViewCell.self, forCellReuseIdentifier: FeedbackTable.feedbackIdentifier)
    }
    
    func loadCell<T>(_ name: String, index: IndexPath) -> T {
        return findCell(name, index: index)!
    }
    
    func findCell<T>(_ name: String, index: IndexPath) -> T? {
        return identifiedCell(name, index: index) as? T
    }
    
    func identifiedCell(_ name: String, index: IndexPath) -> UITableViewCell {
        return self.tableView.dequeueReusableCell(withIdentifier: name, for: index)
    }

    func feedbackCellWithText(_ tableView: UITableView, indexPath: IndexPath, text: String) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: FeedbackTable.feedbackIdentifier, for: indexPath)
        if let label = cell.textLabel {
            label.lineBreakMode = NSLineBreakMode.byWordWrapping
            label.numberOfLines = 0
            label.text = text
            label.textColor = PimpColors.titles
        }
        return cell
    }

}
