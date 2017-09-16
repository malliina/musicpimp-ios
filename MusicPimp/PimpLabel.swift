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
}
