//
//  CompositeDisposable.swift
//  MusicPimp
//
//  Created by Michael Skogberg on 30/10/2016.
//  Copyright © 2016 Skogberg Labs. All rights reserved.
//

import Foundation

class CompositeDisposable : Disposable {
    let inner: [Disposable]
    
    init(inner: [Disposable]) {
        self.inner = inner
    }
    
    func dispose() {
        inner.forEach { $0.dispose() }
    }
}
