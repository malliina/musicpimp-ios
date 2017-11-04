//
//  Credits.swift
//  MusicPimp
//
//  Created by Michael Skogberg on 23/04/2017.
//  Copyright © 2017 Skogberg Labs. All rights reserved.
//

import Foundation
import SnapKit

// https://medium.com/@kenzai/how-to-write-clean-beautiful-storyboard-free-views-in-swift-with-snapkit-443e74fc23b2
class Credits: PimpViewController {
    let developedLabel = PimpLabel.centered(text: "Developed by Michael Skogberg.")
    let designedLabel = PimpLabel.centered(text: "Design by Alisa.")
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.title = "CREDITS"
        initUI()
    }

    func initUI() {
        addSubviews(views: [developedLabel, designedLabel])
        
        developedLabel.snp.makeConstraints { make in
            make.leadingMargin.trailingMargin.centerX.equalToSuperview()
            make.centerY.equalToSuperview().offset(-70)
        }
        
        designedLabel.snp.makeConstraints { make in
            make.leadingMargin.trailingMargin.centerX.equalToSuperview()
            make.bottom.equalToSuperview().inset(16)
        }
    }
}
