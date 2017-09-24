//
//  SideBySideTopList.swift
//  MusicPimp
//
//  Created by Michael Skogberg on 24/09/2017.
//  Copyright © 2017 Skogberg Labs. All rights reserved.
//

import Foundation

class SideBySideTopList: ContainerParent {
    let popular = MostPopularList()
    let recent = MostRecentList()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        popular.showHeader = true
        recent.showHeader = true
        snapSideBySide()
    }
    
    func snapSideBySide() {
        initChild(popular)
        initChild(recent)
        // side-by-side, equal width
        popular.view.snp.makeConstraints { (make) in
            make.top.equalTo(view.snp.topMargin).offset(8)
            make.bottom.equalTo(playbackFooter.snp.top)
            make.leading.equalTo(view)
            make.trailing.equalTo(recent.view.snp.leading)
            make.width.equalTo(recent.view)
        }
        recent.view.snp.makeConstraints { (make) in
            make.top.equalTo(view.snp.topMargin).offset(8)
            make.bottom.equalTo(playbackFooter.snp.top)
            make.trailing.equalTo(view)
            make.leading.equalTo(popular.view.snp.trailing)
        }
    }
}
