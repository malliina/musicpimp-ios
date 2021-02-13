//
//  FlipController.swift
//  MusicPimp
//
//  Created by Michael Skogberg on 24/09/2017.
//  Copyright © 2017 Skogberg Labs. All rights reserved.
//

import Foundation

/// A ViewController with a UISegmentedControl on top that flips between two child ViewControllers
class FlipController: ContainerParent {
    private let log = LoggerFactory.shared.vc(FlipController.self)
    // Override: name of the first segment
    var firstTitle: String { get { "First" } }
    // Override: name of the second segment
    var secondTitle: String { get { "Second" } }
    
    var flipAnimationDuration: TimeInterval { 0.4 }
    
    var scopeSegment: UISegmentedControl? = nil
    
    var left: UIViewController? = nil
    var right: UIViewController? = nil
    
    override func viewDidLoad() {
        super.viewDidLoad()
        initUI()
    }
    
    func initUI() {
        let scope = UISegmentedControl(items: [firstTitle, secondTitle])
        if #available(iOS 13.0, *) {
            scope.selectedSegmentTintColor = PimpColors.shared.background
        } else {
            // Fallback on earlier versions
        }
        scopeSegment = scope
        initScope(scope)
        addSubviews(views: [scope])
        scope.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(8)
            make.leadingMargin.trailingMargin.equalToSuperview()
            make.height.equalTo(32)
        }
        left = buildFirst()
        right = buildSecond()
        if let left = left {
            initChild(left)
            snap(child: left)
            onSwapped(to: left)
        }
    }
    
    /// Override: return the first viewcontroller
    func buildFirst() -> UIViewController {
        UIViewController()
    }
    
    /// Override: return the second viewcontroller
    func buildSecond() -> UIViewController {
        UIViewController()
    }
    
    /// Optionally override: Called when a viewcontroller has been installed
    func onSwapped(to: UIViewController) { }
    
    func snap(child: UIViewController) {
        child.view.snp.makeConstraints { make in
            make.top.equalTo(scopeSegment!.snp.bottom).offset(8)
            make.leading.trailing.equalTo(view)
            make.bottom.equalTo(playbackFooter.snp.top)
        }
    }
    
    fileprivate func initScope(_ ctrl: UISegmentedControl) {
        ctrl.selectedSegmentIndex = 0
        ctrl.addTarget(self, action: #selector(scopeChanged(_:)), for: .valueChanged)
        ctrl.setTitleTextAttributes([NSAttributedString.Key.foregroundColor: PimpColors.shared.tintColor], for: .normal)
    }
    
    @objc func scopeChanged(_ sender: UISegmentedControl) {
        switch sender.selectedSegmentIndex {
        case 0:
            if let left = left, let right = right {
                swap(oldVc: right, newVc: left, options: .transitionFlipFromLeft)
            }
        case 1:
            if let left = left, let right = right {
                swap(oldVc: left, newVc: right, options: .transitionFlipFromRight)
            }
        default:
            log.error("Unknown segment index, must be 0 or 1.")
        }
    }
    
    // https://developer.apple.com/library/content/featuredarticles/ViewControllerPGforiPhoneOS/ImplementingaContainerViewController.html
    func swap(oldVc: UIViewController, newVc: UIViewController, options: UIView.AnimationOptions) {
        oldVc.willMove(toParent: nil)
        self.addChild(newVc)
        self.transition(from: oldVc, to: newVc, duration: flipAnimationDuration, options: options, animations: { self.snap(child: newVc) }) { _ in
            oldVc.removeFromParent()
            newVc.didMove(toParent: self)
            self.onSwapped(to: newVc)
        }
    }
}
