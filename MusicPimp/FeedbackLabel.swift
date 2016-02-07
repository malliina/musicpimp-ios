//
//  FeedbackLabel.swift
//  MusicPimp
//
//  Created by Michael Skogberg on 07/02/16.
//  Copyright © 2016 Skogberg Labs. All rights reserved.
//

import Foundation

class FeedbackLabel: UILabel {
    override func drawTextInRect(rect: CGRect) {
        let insets: UIEdgeInsets = UIEdgeInsets(top: 0.0, left: 8.0, bottom: 0.0, right: 8.0)
        super.drawTextInRect(UIEdgeInsetsInsetRect(rect, insets))
    }
}
