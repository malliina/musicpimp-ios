//
//  SavedPlaylistCell.swift
//  MusicPimp
//
//  Created by Michael Skogberg on 01/09/2018.
//  Copyright © 2018 Skogberg Labs. All rights reserved.
//

import Foundation

class SavedPlaylistCell: PimpCell {
    let nameLabel = PimpLabel.create(fontSize: 22)
    let countLabel = PimpLabel.create(textColor: .lightGray, fontSize: 20)
    
    let spacing = 16
    
    override func configureView() {
        contentView.addSubview(nameLabel)
        nameLabel.snp.makeConstraints { (make) in
            make.top.equalToSuperview().offset(spacing)
            make.leading.equalTo(contentView.snp.leadingMargin)
            make.bottom.equalToSuperview().inset(spacing)
        }
        contentView.addSubview(countLabel)
        countLabel.snp.makeConstraints { (make) in
            make.centerY.equalTo(nameLabel)
            make.leading.equalTo(nameLabel.snp.trailing).offset(spacing)
            make.trailing.equalTo(contentView.snp.trailingMargin)
            make.width.equalTo(60)
        }
    }
    
    func fill(name: String, count: Int) {
        nameLabel.text = name
        countLabel.text = "\(count)"
    }
}
