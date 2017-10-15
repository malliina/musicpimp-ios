//
//  DetailedCell.swift
//  MusicPimp
//
//  Created by Michael Skogberg on 14/05/2017.
//  Copyright © 2017 Skogberg Labs. All rights reserved.
//

import Foundation

class DetailedCell: PimpCell {
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: .value1, reuseIdentifier: reuseIdentifier)
        initCell()
    }
    
    init(reuseIdentifier: String) {
        super.init(style: .value1, reuseIdentifier: reuseIdentifier)
        initCell()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        initCell()
    }
    
    func initCell() {
        detailTextLabel?.textColor = PimpColors.titles
    }
}
