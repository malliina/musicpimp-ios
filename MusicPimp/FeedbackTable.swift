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
        self.tableView?.registerClass(UITableViewCell.self, forCellReuseIdentifier: FeedbackTable.feedbackIdentifier)
    }
    
    func loadCell<T>(name: String, index: NSIndexPath) -> T {
        return findCell(name, index: index)!
    }
    
    func findCell<T>(name: String, index: NSIndexPath) -> T? {
        return identifiedCell(name, index: index) as? T
    }
    
    func identifiedCell(name: String, index: NSIndexPath) -> UITableViewCell {
        return self.tableView.dequeueReusableCellWithIdentifier(name, forIndexPath: index)
    }
    
    func fixAppearance(cell: UITableViewCell) {
        cell.backgroundColor = PimpColors.background
        cell.textLabel?.textColor = PimpColors.titles
    }

    func feedbackCellWithText(tableView: UITableView, indexPath: NSIndexPath, text: String) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(FeedbackTable.feedbackIdentifier, forIndexPath: indexPath)
        if let label = cell.textLabel {
            label.lineBreakMode = NSLineBreakMode.ByWordWrapping
            label.numberOfLines = 0
            label.text = text
        }
        fixAppearance(cell)
        return cell
    }

}
