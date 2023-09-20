import Foundation
import UIKit
import RxSwift

class BaseTableController: UITableViewController {
    private let log = LoggerFactory.shared.vc(BaseTableController.self)
    let settings = PimpSettings.sharedInstance
    
    let limiter = Limiter.sharedInstance
    var currentFeedback: String? = nil
    let bag = DisposeBag()
    
    init() {
        super.init(style: UITableView.Style.plain)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // The background color when there are no more rows
        self.view.backgroundColor = colors.background
        // Removes separators when there are no more rows
        self.tableView.tableFooterView = UIView()
        
        navigationController?.navigationBar.titleTextAttributes = [
            NSAttributedString.Key.font: colors.titleFont,
            NSAttributedString.Key.foregroundColor: colors.titles
        ]
        edgesForExtendedLayout = []
        // Does not add left-right margins to table cells on iPad Pro+
        self.tableView.cellLayoutMarginsFollowReadableWidth = false
    }
    
    func registerCell(reuseIdentifier: String) {
        self.tableView?.register(UITableViewCell.self, forCellReuseIdentifier: reuseIdentifier)
    }
    
    func loadCell<T>(_ name: String, index: IndexPath) -> T {
        findCell(name, index: index)!
    }
    
    func findCell<T>(_ name: String, index: IndexPath) -> T? {
        identifiedCell(name, index: index) as? T
    }
    
    func identifiedCell(_ name: String, index: IndexPath) -> UITableViewCell {
        self.tableView.dequeueReusableCell(withIdentifier: name, for: index)
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        1
    }
    
    func renderTable(_ feedback: String? = nil) {
        renderTable(feedback) { () }
    }
    
    func renderTable(_ feedback: String?, _ afterData: @escaping () -> Void) {
        onUiThread {
            self.reloadTable(feedback: feedback)
            afterData()
        }
    }
    
    func reloadTable(feedback: String?) {
//        log.info("Reloading table...")
        if let feedback = feedback {
            self.setFeedback(feedback)
        } else {
            self.clearFeedback()
        }
        self.tableView.reloadData()
    }
    
    func onUiThread(_ code: @escaping () -> Void) {
        Util.onUiThread(code)
    }
    
    func setFeedback(_ feedback: String) {
        currentFeedback = feedback
        configureTable(background: self.feedbackLabel(feedback), separatorStyle: .none)
    }
    
    func clearFeedback() {
        currentFeedback = nil
        configureTable(background: nil, separatorStyle: .singleLine)
    }
    
    func configureTable(background: UIView?, separatorStyle: UITableViewCell.SeparatorStyle) {
        self.tableView.backgroundView = background
        self.tableView.separatorStyle = separatorStyle
    }
    
    func customFooter(_ text: String) -> UIView {
        let content = UIView()
        let label = PimpLabel.footerLabel(text)
        content.addSubview(label)
        label.snp.makeConstraints{ make in
            make.leading.trailing.equalToSuperview().inset(16)
        }
        return content
    }
    
    func feedbackLabel(_ text: String) -> UILabel {
        // makes no difference afaik, used in a backgroundView so its size is the same as that of the table
        let frame = CGRect(x: 0, y: 0, width: self.view.bounds.size.width, height: self.view.bounds.size.height)
        let label = FeedbackLabel(frame: frame)
        label.textColor = colors.titles
        label.text = text
        label.numberOfLines = 0
        label.textAlignment = .center
        return label
    }
    
    func clickedRow(_ touchEvent: AnyObject) -> Int? {
        return clickedIndexPath(touchEvent)?.row
    }
    
    // TODO add link to source (SO?)
    func clickedIndexPath(_ touchEvent: AnyObject) -> IndexPath? {
        if let touch = touchEvent.allTouches??.first {
            let point = touch.location(in: tableView)
            return tableView.indexPathForRow(at: point)
        }
        return nil
    }
    
    func onError(_ error: Error) {
        Util.onError(error)
    }
    
    func runSingle<T>(_ o: Single<T>, onResult: @escaping (T) -> Void) {
        run(o.asObservable(), onResult: onResult)
    }
    
    func run<T>(_ o: Observable<T>, onResult: @escaping (T) -> Void) {
        o.subscribe { (event) in
            switch event {
            case .next(let t): onResult(t)
            case .error(let err): self.onError(err)
            case .completed: ()
            }
        }.disposed(by: bag)
    }
}

class IAPConstants {
    static let Title = "Limit reached"
    static let Message = "The free version of this app lets you play a couple of tracks per day. A one-time purchase unlocks MusicPimp Premium which enables unlimited playback."
    static let OkText = "Get Premium"
    static let CancelText = "Not interested"
}

extension UIViewController {
    func limitChecked<T>(_ code: () -> T) -> T? {
        if Limiter.sharedInstance.isWithinLimit() {
            return code()
        } else {
            suggestPremium()
            return nil
        }
    }
    
    func suggestPremium() {
        let sheet = UIAlertController(title: IAPConstants.Title, message: IAPConstants.Message, preferredStyle: UIAlertController.Style.alert)
        let premiumAction = UIAlertAction(title: IAPConstants.OkText, style: UIAlertAction.Style.default) { a -> Void in
            self.navigationController?.pushViewController(IAPViewController(), animated: true)
        }
        let notInterestedAction = UIAlertAction(title: IAPConstants.CancelText, style: UIAlertAction.Style.cancel) { a -> Void in
        }
        sheet.addAction(premiumAction)
        sheet.addAction(notInterestedAction)
        if let popover = sheet.popoverPresentationController {
            popover.sourceView = self.view
        }
        self.present(sheet, animated: true, completion: nil)
    }
}
