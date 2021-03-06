//
//  PimpMusicItemCell.swift
//  MusicPimp
//
//  Created by Michael Skogberg on 02/08/15.
//  Copyright (c) 2015 Skogberg Labs. All rights reserved.
//

import Foundation

class PimpMusicItemCell : CustomAccessoryCell {
    
    @IBOutlet var progressView: UIProgressView!
    
    @IBOutlet var titleLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        titleLabel.textColor = PimpColors.titles
//        backgroundColor = PimpColors.background
//        titleLabel.textColor = PimpColors.titles
    }
}
