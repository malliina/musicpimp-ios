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
    private let log = LoggerFactory.vc("FlipController")
    // Override: name of the first segment
    var firstTitle: String { get { return "First" } }
    // Override: name of the second segment
    var secondTitle: String { get { return "Second" } }
    
    var flipAnimationDuration: TimeInterval { return 0.4 }
    
    var scopeSegment: UISegmentedControl? = nil
    var current: UIViewController = UIViewController()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        initUI()
    }
    
    func initUI() {
        let scope = UISegmentedControl(items: [firstTitle, secondTitle])
        scopeSegment = scope
        initScope(scope)
        addSubviews(views: [scope])
        scope.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(8)
            make.leading.trailing.equalToSuperview().inset(8)
            make.height.equalTo(32)
        }
        current = buildFirst()
        initChild(current)
        snap(child: current)
        onSwapped(to: current)
    }
    
    /// Override: return the first viewcontroller
    func buildFirst() -> UIViewController {
        return UIViewController()
    }
    
    /// Override: return the second viewcontroller
    func buildSecond() -> UIViewController {
        return UIViewController()
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
        ctrl.setTitleTextAttributes([NSAttributedStringKey.foregroundColor: PimpColors.tintColor], for: .normal)
    }
    
    @objc func scopeChanged(_ sender: UISegmentedControl) {
        switch sender.selectedSegmentIndex {
        case 0:
            swap(oldVc: current, newVc: buildFirst(), options: .transitionFlipFromLeft)
        case 1:
            swap(oldVc: current, newVc: buildSecond(), options: .transitionFlipFromRight)
        default:
            log.error("Unknown player segment index, must be 0 or 1.")
        }
    }
    
    // https://developer.apple.com/library/content/featuredarticles/ViewControllerPGforiPhoneOS/ImplementingaContainerViewController.html
    func swap(oldVc: UIViewController, newVc: UIViewController, options: UIViewAnimationOptions) {
        oldVc.willMove(toParentViewController: nil)
        self.addChildViewController(newVc)
        self.transition(from: oldVc, to: newVc, duration: flipAnimationDuration, options: options, animations: { self.snap(child: newVc) }) { _ in
            oldVc.removeFromParentViewController()
            newVc.didMove(toParentViewController: self)
            self.current = newVc
            self.onSwapped(to: newVc)
        }
    }
}
