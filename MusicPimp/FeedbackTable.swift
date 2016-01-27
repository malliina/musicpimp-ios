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
    // used both for informational and error messages to the user
    var feedbackMessage: String? = nil

    override func viewDidLoad() {
        super.viewDidLoad()
        self.tableView?.registerClass(UITableViewCell.self, forCellReuseIdentifier: FeedbackTable.feedbackIdentifier)
    }
}
