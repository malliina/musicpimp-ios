//
//  CustomAccessoryCell.swift
//  MusicPimp
//
//  Created by Michael Skogberg on 17/07/16.
//  Copyright © 2016 Skogberg Labs. All rights reserved.
//

import Foundation

class CustomAccessoryCell: PimpCell {
    override func layoutSubviews() {
        super.layoutSubviews()
        // Removes right-side accessory view margin
        // http://stackoverflow.com/questions/20534075/get-rid-of-padding-for-uitableviewcell-custom-accessoryview
        if let accessoryView = self.accessoryView {
            accessoryView.frame.origin.x = self.bounds.width - accessoryView.frame.width
        }
    }
}
