//
//  PimpEndpoint.swift
//  MusicPimp
//
//  Created by Michael Skogberg on 24/05/15.
//  Copyright (c) 2015 Skogberg Labs. All rights reserved.
//

import Foundation
import RxSwift

class PimpEndpoint {
    let log = LoggerFactory.shared.pimp(PimpEndpoint.self)
    let endpoint: Endpoint
    let client: PimpHttpClient
    
    let bag = DisposeBag()
    
    init(endpoint: Endpoint, client: PimpHttpClient) {
        self.endpoint = endpoint
        self.client = client
    }
    
//    func postPlayback(_ cmd: String) {
//        postDict(SimpleCommand(cmd: cmd))
//    }
    
    func postDict<T: Encodable>(_ json: T) {
        client.pimpPost(Endpoints.PLAYBACK, payload: json).subscribe { (event) in
            switch event {
            case .success(let response): self.onSuccess(response.data)
            case .error(let err): self.onError(err)
            }
        }.disposed(by: bag)
    }
    
    func onSuccess(_ data: Data) {
        
    }
    
    func onError(_ error: Error) {
        log.info("Player error: \(error.message)")
    }
}
