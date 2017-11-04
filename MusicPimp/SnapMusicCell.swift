//
// Created by Michael Skogberg on 30/04/2017.
// Copyright (c) 2017 Skogberg Labs. All rights reserved.
//

import Foundation

class SnapMusicCell: SnapCell {
    let title = PimpLabel.create()
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
        contentView.addSubview(title)
        title.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(12)
            make.leadingMargin.trailingMargin.equalTo(contentView)
        }
    }

    func initProgress() {
        contentView.addSubview(progress)
        progress.snp.makeConstraints { make in
            make.leadingMargin.trailingMargin.equalTo(contentView)
            make.top.equalTo(title.snp.bottom).offset(12)
            make.bottom.equalToSuperview()
        }
    }
}
