//
//  EndpointManager.swift
//  MusicPimp
//
//  Created by Michael Skogberg on 17/05/15.
//  Copyright (c) 2015 Skogberg Labs. All rights reserved.
//

import Foundation
import RxSwift

class EndpointManager {
    let key: String
    let settings: PimpSettings
    private let changedSubject = PublishSubject<Endpoint>()
    var changed: Observable<Endpoint> { return changedSubject }
    
    init(key: String, settings: PimpSettings) {
        self.key = key
        self.settings = settings
    }
    
    func saveActive(_ e: Endpoint) -> ErrorMessage? {
        let err =  settings.impl.save(e.id, key: key)
        changedSubject.onNext(e)
        return err
    }
    
    func loadActive() -> Endpoint {
        if let id = settings.impl.load(key) {
            return settings.endpoints().find({ $0.id == id }) ?? Endpoint.Local
        }
        return Endpoint.Local
    }
}
