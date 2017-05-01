//
// Created by Michael Skogberg on 01/05/2017.
// Copyright (c) 2017 Skogberg Labs. All rights reserved.
//

import Foundation

class SnapContainer: PimpViewController {
    let playbackFooter = SnapPlaybackFooter()
    var folder: Folder? = nil
    
    override func viewDidLoad() {
        super.viewDidLoad()
        edgesForExtendedLayout = []
        navigationItem.title = "MUSIC"
        initPlaybackFooter()
        initLibrary()
    }
    
    func initLibrary() {
        let tableVc = LibraryController()
        tableVc.selected = folder
        addChildViewController(tableVc)
        tableVc.view.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(tableVc.view)
        tableVc.view.snp.makeConstraints { make in
            make.leading.equalTo(view.snp.leading)
            make.trailing.equalTo(view.snp.trailing)
            make.top.equalTo(view.snp.top)
            make.bottom.equalTo(playbackFooter.snp.top)
        }
        tableVc.didMove(toParentViewController: self)
    }
    
    func initPlaybackFooter() {
        view.addSubview(playbackFooter)
        playbackFooter.snp.makeConstraints { make in
            make.leading.equalTo(self.view.snp.leadingMargin)
            make.trailing.equalTo(self.view.snp.trailingMargin)
            make.bottom.equalToSuperview()
            make.height.equalTo(44)
        }
    }
}
