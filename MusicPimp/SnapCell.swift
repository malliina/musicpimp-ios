//
//  SnapCell.swift
//  MusicPimp
//
//  Created by Michael Skogberg on 02/05/2017.
//  Copyright © 2017 Skogberg Labs. All rights reserved.
//

import Foundation

class SnapCell: CustomAccessoryCell {
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        configureView()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        configureView()
    }
    
    func configureView() {}
}
