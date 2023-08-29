import Foundation
import RxSwift

class PimpViewController: UIViewController {
    private let log = LoggerFactory.shared.vc(PimpViewController.self)
   
    let bag = DisposeBag()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        edgesForExtendedLayout = []
        view.backgroundColor = colors.background
        navigationController?.navigationBar.titleTextAttributes = [
            NSAttributedString.Key.font: colors.titleFont
        ]
    }
    
    func addSubviews(views: [UIView]) {
        views.forEach { (subView) in
            self.view.addSubview(subView)
        }
    }
    
    func baseConstraints(views: [UIView]) {
        views.forEach { target in
            target.snp.makeConstraints { make in
                make.leadingMargin.trailingMargin.equalToSuperview()
            }
        }
    }
    
    func run<T>(_ o: Single<T>, onResult: @escaping (T) -> Void) {
        o.subscribe { (event) in
            switch event {
            case .success(let t): onResult(t)
            case .failure(let err): self.onError(err)
            }
        }.disposed(by: bag)
    }
    
    func onError(_ error: Error) {
        log.error(error.message)
    }
}
