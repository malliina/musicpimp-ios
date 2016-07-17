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
    
    func loadCell<T>(name: String) -> T {
        let maybeView: T = findView(name)!
        return maybeView
    }
    
    func findView<T>(name: String) -> T? {
        let arr = NSBundle.mainBundle().loadNibNamed(name, owner: self, options: nil)
        return arr[0] as? T
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
