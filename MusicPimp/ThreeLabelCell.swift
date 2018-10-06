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
    let subLeft = PimpLabel.create(textColor: PimpColors.shared.subtitles, fontSize: 15)
    let subRight = PimpLabel.create(textColor: PimpColors.shared.subtitles, fontSize: 15)
    
    override func configureView() {
        if hasAccessory() {
            installTrackAccessoryView(height: MainSubCell.height)
        }
        contentView.addSubview(main)
        contentView.addSubview(subLeft)
        contentView.addSubview(subRight)
        main.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(12)
            make.leading.equalTo(contentView.snp.leadingMargin)
            make.trailing.equalTo(contentView)
        }
        subLeft.snp.makeConstraints { make in
            make.top.equalTo(main.snp.bottom).offset(6)
            make.leading.equalTo(contentView.snp.leadingMargin)
            make.trailing.equalTo(subRight.snp.leading).offset(-8)
            make.bottom.equalToSuperview().inset(12)
        }
        subRight.snp.makeConstraints { make in
            make.top.equalTo(main.snp.bottom).offset(6)
            make.trailing.equalTo(contentView)
            make.bottom.equalToSuperview().inset(12)
            make.width.equalTo(subRightWidth())
        }
    }
    
    func fill(main: String, subLeft: String, subRight: String) {
        self.main.text = main
        self.subLeft.text = subLeft
        self.subRight.text = subRight
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        super.removeAccessoryMargin()
    }
    
    func subRightWidth() -> CGFloat {
        return 140
    }
    
    func hasAccessory() -> Bool {
        return true
    }
}

class MostRecentCell: ThreeLabelCell {
}

class SavedPlaylistCell: ThreeLabelCell {
    override func hasAccessory() -> Bool {
        return false
    }
}

class PlaylistTrackCell: ThreeLabelCell {
    static let identifier = String(describing: PlaylistTrackCell.self)
    
    override func configureView() {
        super.configureView()
        accessoryType = .detailButton
    }
    
    override func hasAccessory() -> Bool {
        return false
    }
}

class MostPopularCell: ThreeLabelCell {
    override func subRightWidth() -> CGFloat {
        return 80
    }
}
