//
//  PimpLabel.swift
//  MusicPimp
//
//  Created by Michael Skogberg on 04/09/16.
//  Copyright © 2016 Skogberg Labs. All rights reserved.
//

import Foundation

class PimpLabel: UILabel {
    static let headerTopMargin: CGFloat = 16
    
    static func footerLabel(_ text: String) -> UILabel {
        let label = create()
        label.text = text
        label.font = label.font.withSize(16)
        label.lineBreakMode = .byWordWrapping
        label.numberOfLines = 0
        label.sizeToFit()
        return label
    }
    
    static func create() -> UILabel {
        let label = UILabel()
        label.textColor = PimpColors.titles
        return label
    }
    
    static func centered(text: String) -> UILabel {
        let label = create()
        label.text = text
        label.numberOfLines = 0
        label.lineBreakMode = .byWordWrapping
        label.textAlignment = .center
        return label
    }
}

extension UILabel {
    func tableHeaderHeight(_ tableView: UITableView) -> CGFloat {
        // Not sure why * 2 is needed - one for UITableViewHeaderCell, the other for the label?
        print("calc height with margin \(tableView.layoutMargins.left)")
        let availableWidth = tableView.frame.width - (tableView.layoutMargins.left) - (tableView.layoutMargins.right)
        return self.sizeThatFits(CGSize(width: availableWidth, height: CGFloat.greatestFiniteMagnitude)).height + PimpLabel.headerTopMargin
    }
}
