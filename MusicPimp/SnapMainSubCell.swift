//
//  SnapMainSubCell.swift
//  MusicPimp
//
//  Created by Michael Skogberg on 01/05/2017.
//  Copyright © 2017 Skogberg Labs. All rights reserved.
//

import Foundation

class SnapMainSubCell: SnapCell {
    let main = UILabel()
    let sub = UILabel()
    
    override func configureView() {
        installTrackAccessoryView()
        main.textColor = PimpColors.titles
        sub.textColor = PimpColors.titles
        contentView.addSubview(main)
        main.snp.makeConstraints { make in
            make.top.equalToSuperview()
            make.leading.equalTo(contentView.snp.leadingMargin)
            make.trailing.equalTo(contentView.snp.trailingMargin)
        }
        
        contentView.addSubview(sub)
        sub.snp.makeConstraints { make in
            make.top.equalTo(main.snp.bottom)
            make.leading.equalTo(contentView.snp.leadingMargin)
            make.trailing.equalTo(contentView.snp.trailingMargin)
            make.bottom.equalToSuperview().inset(8)
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        super.removeAccessoryMargin()
    }
}
