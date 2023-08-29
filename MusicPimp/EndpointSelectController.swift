import Foundation
import UIKit

fileprivate extension Selector {
    static let addClicked = #selector(EndpointSelectController.onAddNew(_:))
}

class EndpointSelectController: BaseTableController, EditEndpointDelegate {
    let log = LoggerFactory.shared.vc(EndpointSelectController.self)
    let endpointIdentifier = "EndpointCell"
    var endpoints: [Endpoint] = []
    
    var selectedIndex: Int? = nil
    var delegate: EditEndpointDelegate? = nil
    
    func use(endpoint: Endpoint) -> Void {
    }
    
    func loadActive() -> Endpoint {
        Endpoint.Local
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: .addClicked)
        self.tableView?.register(UITableViewCell.self, forCellReuseIdentifier: endpointIdentifier)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        endpoints = settings.endpoints()
        updateSelected(loadActive())
        reloadTable(feedback: nil)
    }
    
    func endpointAddedOrUpdated(_ endpoint: Endpoint) {
        log.info("Endpoint added or updated, re-rendering endpoints table.")
        endpoints = settings.endpoints()
        updateSelected(loadActive())
        renderTable()
        delegate?.endpointAddedOrUpdated(endpoint)
    }
    
    func updateSelected(_ selected: Endpoint) {
        let id = selected.id
        if id == Endpoint.Local.id {
            selectedIndex = 0
        } else {
            if let idx = endpoints.firstIndex(where: { $0.id == id }) {
                selectedIndex = idx + 1
            }
        }
    }
    
    @objc func onAddNew(_ sender: UIBarButtonItem) {
        let dest = EditEndpointController()
        dest.delegate = self
        self.present(UINavigationController(rootViewController: dest), animated: true, completion: nil)
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let index = indexPath.row
        let endpoint = endpointForIndex(index)
        let cell = tableView.dequeueReusableCell(withIdentifier: endpointIdentifier, for: indexPath)
        cell.textLabel?.text = endpoint.name
        cell.textLabel?.textColor = PimpColors.shared.titles
        let accessory = index == selectedIndex ? UITableViewCell.AccessoryType.checkmark : UITableViewCell.AccessoryType.none
        cell.accessoryType = accessory
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: false)
        let index = indexPath.row
        if index == selectedIndex {
            return
        }
        let endpoint = endpointForIndex(index)
        use(endpoint: endpoint)
        
        let cell = tableView.cellForRow(at: indexPath)
        cell?.accessoryType = UITableViewCell.AccessoryType.checkmark
        
        if let previous = selectedIndex {
            let previousCell = tableView.cellForRow(at: IndexPath(row: previous, section: 0))
            previousCell?.accessoryType = UITableViewCell.AccessoryType.none
        }
        selectedIndex = index
    }
    
    func endpointForIndex(_ index: Int) -> Endpoint {
        index == 0 ? Endpoint.Local : endpoints[index-1]
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        endpoints.count + 1 // +1 for local endpoint
    }
    
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
    }
    
    override func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        let rowIndex = indexPath.row
        if rowIndex > 0 {
            let edit = endpointRowAction(tableView, title: "Edit") {
                (index: Int) -> Void in
                if let endpoint = self.endpoints.get(index) {
                    let dest = EditEndpointController()
                    dest.delegate = self
                    dest.editedItem = endpoint
                    self.navigationController?.pushViewController(dest, animated: true)
                } else {
                    self.log.error("No endpoint at index \(index)")
                }
            }
            let remove = endpointRowAction(tableView, title: "Remove") {
                (index: Int) -> Void in
                // TODO make EndpointsService with operations on endpoints, then listen for endpointsChanged events and react instead
                let active = self.loadActive()
                let removed = self.endpoints.remove(at: index)
                self.settings.saveAll(self.endpoints)
                if active.id == removed.id {
                    let _ = self.use(endpoint: Endpoint.Local)
                }
                let visualIndex = IndexPath(row: index + 1, section: 0)
                tableView.deleteRows(at: [visualIndex], with: UITableView.RowAnimation.fade)
            }
            return [edit, remove]
        }
        // "this device" is not editable
        return []
    }
    
    func endpointRowAction(_ tableView: UITableView, title: String, f: @escaping (Int) -> Void) -> UITableViewRowAction {
        UITableViewRowAction(style: UITableViewRowAction.Style.default, title: title) {
            (action: UITableViewRowAction, indexPath: IndexPath) -> Void in
            let endIndex = indexPath.row - 1
            if endIndex >= 0 && self.endpoints.count > endIndex {
                f(endIndex)
            }
            tableView.setEditing(false, animated: true)
        }
    }
}
