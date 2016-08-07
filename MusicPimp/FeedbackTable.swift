//
//  FeedbackTable.swift
//  MusicPimp
//
//  Created by Michael Skogberg on 11/01/16.
//  Copyright © 2016 Skogberg Labs. All rights reserved.
//

import Foundation

class FeedbackTable: BaseTableController {
    static let feedbackIdentifier = "FeedbackCell"

    override func viewDidLoad() {
        super.viewDidLoad()
        self.tableView?.registerClass(UITableViewCell.self, forCellReuseIdentifier: FeedbackTable.feedbackIdentifier)
    }
    
    func loadCell<T>(name: String, index: NSIndexPath) -> T {
        return findCell(name, index: index)!
    }
    
    func findCell<T>(name: String, index: NSIndexPath) -> T? {
        return self.tableView.dequeueReusableCellWithIdentifier(name, forIndexPath: index) as? T
    }
    
    func feedbackCellWithText(tableView: UITableView, indexPath: NSIndexPath, text: String) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(FeedbackTable.feedbackIdentifier, forIndexPath: indexPath)
        if let label = cell.textLabel {
            label.lineBreakMode = NSLineBreakMode.ByWordWrapping
            label.numberOfLines = 0
            label.text = text
        }
        return cell
    }

}
