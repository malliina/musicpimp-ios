//
//  MainSubCell.swift
//  MusicPimp
//
//  Created by Michael Skogberg on 16/09/2017.
//  Copyright © 2017 Skogberg Labs. All rights reserved.
//

import Foundation

class MainSubCell: SnapCell {
    // empirical - no clue how
    static let height: CGFloat = 74
    let main = PimpLabel.create()
    let sub = PimpLabel.create()
    
    override func configureView() {
        installTrackAccessoryView(height: MainSubCell.height)
        contentView.addSubview(main)
        main.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(12)
            make.leadingMargin.trailingMargin.equalTo(contentView)
        }
        
        contentView.addSubview(sub)
        sub.snp.makeConstraints { make in
            make.top.equalTo(main.snp.bottom).offset(8)
            make.leadingMargin.trailingMargin.equalTo(contentView)
            make.bottom.equalToSuperview().inset(12)
        }
    }
}
