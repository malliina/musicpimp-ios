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
    let developedLabel = PimpLabel.create()
    let designedLabel = PimpLabel.create()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.title = "CREDITS"
        initUI()
    }

    func initUI() {
        addSubviews(views: [developedLabel, designedLabel])
        
        initLabel(label: developedLabel, text: "Developed by Michael Skogberg.")
        initLabel(label: designedLabel, text: "Design by Alisa.")
        
        developedLabel.snp.makeConstraints { make in
            make.leading.equalTo(self.view.snp.leadingMargin)
            make.trailing.equalTo(self.view.snp.trailingMargin)
            make.centerX.equalToSuperview()
            make.centerY.equalToSuperview().offset(-8)
//            make.top.greaterThanOrEqualTo(self.view.snp.topMargin).offset(16)
        }
        
        designedLabel.snp.makeConstraints { make in
            make.leading.equalTo(self.view.snp.leadingMargin)
            make.trailing.equalTo(self.view.snp.trailingMargin)
            make.centerX.equalToSuperview()
            make.bottom.equalTo(self.view.snp.bottomMargin).offset(-8)
        }
    }
    
    func initLabel(label: UILabel, text: String) {
        label.text = text
        label.numberOfLines = 0
        label.lineBreakMode = .byWordWrapping
        label.textAlignment = .center
    }
}
