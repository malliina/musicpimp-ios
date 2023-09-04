
import Foundation

class SearchAlarmTrackController: SearchableMusicController {
    let log = LoggerFactory.shared.vc(SearchAlarmTrackController.self)
    
    var alarm: MutableAlarm? = nil
    
    override func viewDidLoad() {
        super.viewDidLoad()
        reloadTable(feedback: "Search for a track")
        self.tableView.tableHeaderView = self.searchController.searchBar
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        searchController.isActive = true
    }
    
    override func didPresentSearchController(_ searchController: UISearchController) {
        searchController.searchBar.becomeFirstResponder()
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if let item = itemAt(tableView, indexPath: indexPath), let track = item as? Track {
            alarm?.track = track
        }
        tableView.deselectRow(at: indexPath, animated: false)
        tableView.reloadRows(at: [indexPath], with: .none)
        searchController.isActive = false
        // goBack() would go back two pages here for some reason
        self.navigationController?.popViewController(animated: false)
    }
}
