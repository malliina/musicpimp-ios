//
//  PimpButton.swift
//  MusicPimp
//
//  Created by Michael Skogberg on 04/09/16.
//  Copyright © 2016 Skogberg Labs. All rights reserved.
//

import Foundation

/// Similar to https://cocoacasts.com/elegant-controls-in-swift-with-closures/
class PimpButton: UIButton {
    let colors = PimpColors.shared
    var onTouchUpInside: ((UIButton) -> ())? = nil {
        didSet {
            let selector = #selector(didTouchUpInside(sender:))
            if onTouchUpInside != nil {
                addTarget(self, action: selector, for: .touchUpInside)
            } else {
                removeTarget(self, action: selector, for: .touchUpInside)
            }
        }
    }
    
    required init(title: String) {
        super.init(frame: .zero)
        setTitle(title, for: .normal)
        setTitleColor(colors.tintColor, for: .normal)
    }
    
    convenience init(title: String, touchUp: @escaping (UIButton) -> ()) {
        self.init(title: title)
        onTouchUpInside = touchUp
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @objc private func didTouchUpInside(sender: UIButton) {
        self.onTouchUpInside?(sender)
    }
   
    static func with(title: String) -> UIButton {
        let button = UIButton()
        button.setTitle(title, for: .normal)
        button.setTitleColor(PimpColors.shared.tintColor, for: .normal)
        return button
    }
}

extension UIButton {
    func onClick(target: Any?, code: Selector) {
        self.addTarget(target, action: code, for: .touchUpInside)
    }
}
