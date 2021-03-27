//
//  SnapFolderCell.swift
//  MusicPimp
//
//  Created by Michael Skogberg on 27.3.2021.
//  Copyright © 2021 Skogberg Labs. All rights reserved.
//

import Foundation

class DisclosureCell: SnapCell {
    override func configureView() {
        super.configureView()
        installDisclosureAccessoryView()
    }
}
