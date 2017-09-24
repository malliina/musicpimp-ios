//
//  MainSubCell.swift
//  MusicPimp
//
//  Created by Michael Skogberg on 16/09/2017.
//  Copyright © 2017 Skogberg Labs. All rights reserved.
//

import Foundation

class MainSubCell: SnapCell {
    let main = PimpLabel.create()
    let sub = PimpLabel.create()
    
    override func configureView() {
        installTrackAccessoryView()
        contentView.addSubview(main)
        main.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(12)
            make.leading.equalTo(contentView.snp.leadingMargin)
            make.trailing.equalTo(contentView.snp.trailingMargin)
        }
        
        contentView.addSubview(sub)
        sub.snp.makeConstraints { make in
            make.top.equalTo(main.snp.bottom).offset(8)
            make.leading.equalTo(contentView.snp.leadingMargin)
            make.trailing.equalTo(contentView.snp.trailingMargin)
            make.bottom.equalToSuperview().inset(12)
        }
    }
}
