//
//  PimpLabel.swift
//  MusicPimp
//
//  Created by Michael Skogberg on 04/09/16.
//  Copyright © 2016 Skogberg Labs. All rights reserved.
//

import Foundation

class PimpLabel: UILabel {
    static func footerLabel(_ text: String) -> UILabel {
        let label = UILabel()
        label.text = text
        label.textColor = PimpColors.titles
        label.font = label.font.withSize(12)
        label.lineBreakMode = .byWordWrapping
        label.numberOfLines = 0
        label.sizeToFit()
        return label
    }
}
