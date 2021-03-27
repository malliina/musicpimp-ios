//
//  SnapFolderCell.swift
//  MusicPimp
//
//  Created by Michael Skogberg on 27.3.2021.
//  Copyright © 2021 Skogberg Labs. All rights reserved.
//

import Foundation

class DisclosureCell: SnapCell {
    override func configureView() {
        super.configureView()
        installDisclosureAccessoryView()
        
//        let disclosure = createAccessory(height: CustomAccessoryCell.defaultCellHeight, image: CustomAccessoryCell.disclosureAccessory)
//        contentView.addSubview(disclosure)
//        disclosure.snp.makeConstraints { make in
//            make.top.equalToSuperview().offset(topMargin)
//            make.leading.equalTo(detail.snp.trailingMargin)
//            make.trailing.equalTo(contentView.snp.trailing)
//        }
    }
    
//    func installDisclosureAccessoryView(height: CGFloat = CustomAccessoryCell.defaultCellHeight) {
//        self.accessoryView = createAccessory(height: height, image: CustomAccessoryCell.folderAccessory)
//    }
}
