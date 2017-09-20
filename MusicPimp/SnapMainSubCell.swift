//
//  SnapMainSubCell.swift
//  MusicPimp
//
//  Created by Michael Skogberg on 01/05/2017.
//  Copyright © 2017 Skogberg Labs. All rights reserved.
//

import Foundation

class SnapMainSubCell: MainSubCell {
    override func layoutSubviews() {
        super.layoutSubviews()
        super.removeAccessoryMargin()
    }
}
