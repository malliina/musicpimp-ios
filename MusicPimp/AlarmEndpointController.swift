import Foundation

protocol AlarmEndpointDelegate {
    func endpointChanged(newEndpoint: Endpoint)
}

class AlarmEndpointController: BaseTableController {
    let endpointIdentifier = "EndpointCell"
    
    private var endpoints: [Endpoint] = []
    var selectedId: String? = nil
    var delegate: AlarmEndpointDelegate? = nil
    
    init(d: AlarmEndpointDelegate) {
        super.init()
        self.delegate = d
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.tableView!.register(PimpCell.self, forCellReuseIdentifier: endpointIdentifier)
        endpoints = settings.endpoints().filter { $0.supportsAlarms }
        selectedId = settings.defaultNotificationEndpoint()?.id
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        renderTable(endpoints.isEmpty ? "No eligible playback devices." : nil)
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return currentFeedback == nil ? endpoints.count : 0
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let index = indexPath.row
        let endpoint = endpoints[index]
        let cell = tableView.dequeueReusableCell(withIdentifier: endpointIdentifier, for: indexPath)
        cell.textLabel?.text = endpoint.name
        cell.accessoryType = endpoint.id == selectedId ? .checkmark : .none
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: false)
        let endpoint = endpoints[indexPath.row]
        selectedId = endpoint.id
        settings.saveDefaultNotificationsEndpoint(endpoint, publish: true)
        reloadTable(feedback: nil)
        delegate?.endpointChanged(newEndpoint: endpoint)
    }
}
