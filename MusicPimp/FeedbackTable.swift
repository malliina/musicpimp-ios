
import Foundation

class FeedbackTable: BaseTableController {
    static let mainAndSubtitleCellKey = "MainAndSubtitleCell"
    static let mainAndSubtitleCellHeight: CGFloat = 65
    static let feedbackIdentifier = "FeedbackCell"

    override func viewDidLoad() {
        super.viewDidLoad()
        registerCell(reuseIdentifier: FeedbackTable.feedbackIdentifier)
    }
}

extension BaseTableController {
    func feedbackCellWithText(_ tableView: UITableView, indexPath: IndexPath, text: String) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: FeedbackTable.feedbackIdentifier, for: indexPath)
        if let label = cell.textLabel {
            label.lineBreakMode = .byWordWrapping
            label.numberOfLines = 0
            label.text = text
            label.textColor = colors.titles
        }
        return cell
    }
}
