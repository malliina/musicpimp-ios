import Foundation
import RxSwift

class LibraryManager: EndpointManager {
    let log = LoggerFactory.shared.pimp(LibraryManager.self)
    static let sharedInstance = LibraryManager()
    
    fileprivate var activeLibrary: LibraryType
    var active: LibraryType { get { activeLibrary } }
    private let librarySubject = PublishSubject<LibraryType>()
    var libraryUpdated: Observable<LibraryType> { librarySubject }
 
    init() {
        let settings = PimpSettings.sharedInstance
        activeLibrary = Libraries.fromEndpoint(settings.activeEndpoint(PimpSettings.LIBRARY))
        super.init(key: PimpSettings.LIBRARY, settings: settings)
    }
    
    func endpoints() -> [Endpoint] {
        settings.endpoints()
    }
    
    func use(endpoint: Endpoint) -> LibraryType {
        let _ = saveActive(endpoint)
        let client = Libraries.fromEndpoint(endpoint)
        activeLibrary = client
        log.info("Library set to \(endpoint.name)")
        librarySubject.onNext(client)
        return client
    }
}
