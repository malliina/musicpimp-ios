//
//  ThreeLabelCell.swift
//  MusicPimp
//
//  Created by Michael Skogberg on 05/11/2017.
//  Copyright © 2017 Skogberg Labs. All rights reserved.
//

import Foundation

class ThreeLabelCell: CustomAccessoryCell {
    // empirical - no clue how. elements + margins equal 62 pixels
    static let height: CGFloat = 70
    let main = PimpLabel.create()
    let subLeft = PimpLabel.create(textColor: PimpColors.subtitles, fontSize: 15)
    let subRight = PimpLabel.create(textColor: PimpColors.subtitles, fontSize: 15)
    
    override func configureView() {
        installTrackAccessoryView(height: MainSubCell.height)
        contentView.addSubview(main)
        main.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(12)
            make.leading.equalTo(contentView.snp.leadingMargin)
            make.trailing.equalTo(contentView)
        }
        contentView.addSubview(subLeft)
        contentView.addSubview(subRight)
        subLeft.snp.makeConstraints { make in
            make.top.equalTo(main.snp.bottom).offset(6)
            make.leading.equalTo(contentView.snp.leadingMargin)
            make.trailing.equalTo(subRight.snp.leading).offset(-8)
            make.bottom.equalToSuperview().inset(12)
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        super.removeAccessoryMargin()
    }
}
