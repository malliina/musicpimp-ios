//
//  SnapCell.swift
//  MusicPimp
//
//  Created by Michael Skogberg on 02/05/2017.
//  Copyright © 2017 Skogberg Labs. All rights reserved.
//

import Foundation

class SnapCell: CustomAccessoryCell {
    let title = PimpLabel.create()
    let detail = PimpLabel.create()
    var zeroAccessoryMargin: Bool = true
    let topMargin = 12
    
    override func configureView() {
        initLabels()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        if zeroAccessoryMargin {
            super.removeAccessoryMargin()
        }
    }

    func initLabels() {
        contentView.addSubview(title)
        title.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(topMargin)
            make.leading.equalTo(contentView.snp.leadingMargin)
        }
        contentView.addSubview(detail)
        detail.textAlignment = .right
        detail.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(topMargin)
            make.leading.equalTo(title.snp.trailingMargin)
            make.trailing.equalTo(contentView.snp.trailing)
        }
    }
}
