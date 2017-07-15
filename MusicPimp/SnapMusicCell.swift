//
// Created by Michael Skogberg on 30/04/2017.
// Copyright (c) 2017 Skogberg Labs. All rights reserved.
//

import Foundation

class SnapMusicCell: SnapCell {
    let title = UILabel()
    let progress = UIProgressView(progressViewStyle: .default)

    override func configureView() {
        installTrackAccessoryView()
        initTitle()
        initProgress()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        super.removeAccessoryMargin()
    }

    func initTitle() {
        title.textColor = PimpColors.titles
        contentView.addSubview(title)
        title.snp.makeConstraints { make in
            make.top.equalToSuperview()
            make.leading.equalTo(contentView.snp.leadingMargin)
            make.trailing.equalTo(contentView.snp.trailingMargin)
        }
    }

    func initProgress() {
        contentView.addSubview(progress)
        progress.snp.makeConstraints { make in
            make.leading.equalTo(contentView.snp.leadingMargin)
            make.trailing.equalTo(contentView.snp.trailingMargin)
            make.top.equalTo(title.snp.bottom)
            make.bottom.equalToSuperview()
        }
    }
}
