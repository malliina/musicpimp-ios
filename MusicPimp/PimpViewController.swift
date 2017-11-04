//
//  PimpViewController.swift
//  MusicPimp
//
//  Created by Michael Skogberg on 01/09/16.
//  Copyright © 2016 Skogberg Labs. All rights reserved.
//

import Foundation

class PimpViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        edgesForExtendedLayout = []
        self.view.backgroundColor = PimpColors.background
        navigationController?.navigationBar.titleTextAttributes = [
            NSAttributedStringKey.font: PimpColors.titleFont
        ]
    }
    
    func addSubviews(views: [UIView]) {
        views.forEach { (subView) in
            self.view.addSubview(subView)
        }
    }
    
    func baseConstraints(views: [UIView]) {
        views.forEach { target in
            target.snp.makeConstraints { make in
                make.leadingMargin.trailingMargin.equalToSuperview()
            }
        }
    }
}
