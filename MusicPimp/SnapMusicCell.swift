//
// Created by Michael Skogberg on 30/04/2017.
// Copyright (c) 2017 Skogberg Labs. All rights reserved.
//

import Foundation

class SnapMusicCell: SnapCell {
    let title = UILabel()
    let progress = UIProgressView(progressViewStyle: .default)

    override func configureView() {
        initTitle()
        initProgress()
    }

    func initTitle() {
        addSubview(title)
        title.textColor = PimpColors.titles
        title.snp.makeConstraints { make in
            make.top.equalToSuperview()
            make.leading.equalTo(self.snp.leadingMargin)
            make.trailing.equalTo(self.snp.trailingMargin)
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

class SnapCell: UITableViewCell {
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        configureView()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        configureView()
    }
    
    func configureView() {}
}
