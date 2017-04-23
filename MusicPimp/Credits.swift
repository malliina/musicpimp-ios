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
        navigationItem.title = "SNAPCREDITS"
        view.snp.makeConstraints { make in
//            make.top.equalTo(topLayoutGuide.snp.bottom)
//            make.bottom.equalTo(bottomLayoutGuide.snp.top)
//            make.top.equalTo(topLayoutGuide.snp.bottom)
            make.height.equalTo(300)
        }
//        self.edgesForExtendedLayout = .all
//        self.extendedLayoutIncludesOpaqueBars = true
    }
    
    override func loadView() {
//        self.edgesForExtendedLayout = .left
//        let wrapper = UIView()
//        wrapper.snp.makeConstraints { make in
//            make.top.equalTo(topLayoutGuide.snp.bottom)
//            make.bottom.equalTo(bottomLayoutGuide.snp.top)
//        }
//
//        let wrapper = WrapperView()
//        wrapper.addSubview(CreditsView())
        view = CreditsView()
    }
}

class WrapperView: BaseView {
    var view: UIView? = nil
}

class CreditsView: BaseView {
    let developedLabel = UILabel()
    let designedLabel = UILabel()
    
    override func configureView() {
        backgroundColor = UIColor.cyan
        addSubviews(views: [developedLabel, designedLabel])
        
        initLabel(label: developedLabel, text: "Developed by Michael Skogberg.")
        initLabel(label: designedLabel, text: "Design by Alisa.")
        
        developedLabel.snp.makeConstraints { make in
            make.leading.equalToSuperview()
            make.trailing.equalToSuperview()
            make.centerX.equalToSuperview()
            make.centerY.equalToSuperview()
        }
//
//        designedLabel.snp.makeConstraints { make in
//            make.leading.equalToSuperview()
//            make.trailing.equalToSuperview()
//            make.centerX.equalToSuperview()
//            make.bottom.equalToSuperview().offset(-8)
//        }
//        designedLabel.bottomAnchor.constraint(equalTo: bottomAnchor)
    }
    
    func initLabel(label: UILabel, text: String) {
        label.textColor = PimpColors.titles
        label.text = text
        label.numberOfLines = 0
        label.lineBreakMode = .byWordWrapping
        label.textAlignment = .center
    }
}

// https://medium.com/swift-digest/good-swift-bad-swift-part-1-f58f71da3575
class BaseView: UIView {
    init() {
        super.init(frame: CGRect.zero)
        configureView()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        configureView()
    }
    
    func addSubviews(views: [UIView]) {
        views.forEach(addSubview)
    }
    
    func configureView() {
        
    }
}
