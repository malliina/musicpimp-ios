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
    
    
    func postDict<T: Encodable>(_ json: T) {
        client.pimpPost(Endpoints.PLAYBACK, payload: json).subscribe { (event) in
            switch event {
            case .success(let response): self.onSuccess(response.data)
            case .failure(let err): self.onError(err)
            }
        }.disposed(by: bag)
    }
    
    func onSuccess(_ data: Data) {
        
    }
    
    func onError(_ error: Error) {
        log.info("Player error: \(error.message)")
    }
}
