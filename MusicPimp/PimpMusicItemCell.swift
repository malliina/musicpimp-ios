//
//  PimpMusicItemCell.swift
//  MusicPimp
//
//  Created by Michael Skogberg on 02/08/15.
//  Copyright (c) 2015 Skogberg Labs. All rights reserved.
//

import Foundation
class PimpMusicItemCell : UITableViewCell {
    
    @IBOutlet var progressView: UIProgressView!
    
    @IBOutlet var titleLabel: UILabel!
    
    override func layoutSubviews() {
        super.layoutSubviews()
        // Removes right-side accessory view margin
        // http://stackoverflow.com/questions/20534075/get-rid-of-padding-for-uitableviewcell-custom-accessoryview
        if let accessoryView = self.accessoryView {
            accessoryView.frame.origin.x = self.bounds.width - accessoryView.frame.width
        }
    }    
}
