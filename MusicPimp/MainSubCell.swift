//
//  MainSubCell.swift
//  MusicPimp
//
//  Created by Michael Skogberg on 16/09/2017.
//  Copyright © 2017 Skogberg Labs. All rights reserved.
//

import Foundation

class MainSubCell: SnapCell {
    // empirical - no clue how. elements + margins equal 62 pixels
    static let height: CGFloat = 70
    let main = PimpLabel.create()
    let sub = PimpLabel.create(textColor: PimpColors.shared.subtitles, fontSize: 15)
    
    override func configureView() {
        installTrackAccessoryView(height: MainSubCell.height)
        contentView.addSubview(main)
        main.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(12)
            make.leading.equalTo(contentView.snp.leadingMargin)
            make.trailing.equalTo(contentView)
        }
        
        contentView.addSubview(sub)
        sub.snp.makeConstraints { make in
            make.top.equalTo(main.snp.bottom).offset(6)
            make.leading.equalTo(contentView.snp.leadingMargin)
            make.trailing.equalTo(contentView)
            make.bottom.equalToSuperview().inset(12)
        }
    }
}
