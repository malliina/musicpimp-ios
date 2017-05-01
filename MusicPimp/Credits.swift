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
class Credits: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.title = "CREDITS"
        edgesForExtendedLayout = []
        initUI()
    }

    func initUI() {
//        let credits = CreditsView()
//        view.addSubview(credits)
//        credits.snp.makeConstraints { make in
//            make.edges.equalToSuperview()
//        }
    }

    override func loadView() {
        self.view = CreditsView()
    }
}

class CreditsView: BaseView {
    let developedLabel = UILabel()
    let designedLabel = UILabel()

    override func configureView() {
        addSubviews(views: [developedLabel, designedLabel])

        initLabel(label: developedLabel, text: "Developed by Michael Skogberg.")
        initLabel(label: designedLabel, text: "Design by Alisa.")

        developedLabel.snp.makeConstraints { make in
            make.leading.equalToSuperview()
            make.trailing.equalToSuperview()
            make.centerX.equalToSuperview()
            make.centerY.equalToSuperview()
        }

        designedLabel.snp.makeConstraints { make in
            make.leading.equalToSuperview()
            make.trailing.equalToSuperview()
            make.centerX.equalToSuperview()
            make.bottom.equalToSuperview().offset(-8)
        }
    }
    
    func initLabel(label: UILabel, text: String) {
        label.textColor = PimpColors.titles
        label.text = text
        label.numberOfLines = 0
        label.lineBreakMode = .byWordWrapping
        label.textAlignment = .center
    }
}
