
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
