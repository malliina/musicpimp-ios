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
        addSubview(title)
        title.textColor = PimpColors.titles
        title.snp.makeConstraints { make in
            make.top.equalToSuperview()
            make.leading.equalTo(self.snp.leadingMargin)
            if let accessoryView = accessoryView {
                // snapping to accessoryView.leading didn't work, view hierarchy error
                make.trailing.equalTo(self.snp.trailing).inset(accessoryView.frame.width)
            } else {
                make.trailing.equalTo(self.snp.trailingMargin)
            }
        }
    }

    func initProgress() {
        addSubview(progress)
        progress.snp.makeConstraints { make in
            make.leading.equalTo(self.snp.leadingMargin)
            make.trailing.equalTo(self.snp.trailingMargin)
            make.top.equalTo(title.snp.bottom)
            make.bottom.equalToSuperview()
        }
    }
}
