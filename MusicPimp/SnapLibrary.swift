//
// Created by Michael Skogberg on 30/04/2017.
// Copyright (c) 2017 Skogberg Labs. All rights reserved.
//

import Foundation

class SnapLibrary: UITableViewController {
    let CellIdentifier = "SnapMusicCell"
    let FolderCellIdentifier = "FolderCell"

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.title = "MUSIC"
        self.tableView?.register(SnapMusicCell.self, forCellReuseIdentifier: CellIdentifier)
        self.tableView?.register(UITableViewCell.self, forCellReuseIdentifier: FolderCellIdentifier)
    }

    public override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 3
    }

    public override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let row = indexPath.row
        let isFolder = row == 0
        if isFolder {
            let cell = folderCell(tableView: tableView, indexPath: indexPath)
            cell.textLabel?.text = "Folder \(row)"
            cell.textLabel?.textColor = PimpColors.titles
            return cell
        } else {
            let cell = cellFor(tableView: tableView, indexPath: indexPath)
            cell.title.text = "Row \(row)"
            return cell
        }
    }

    func cellFor(tableView: UITableView, indexPath: IndexPath) -> SnapMusicCell {
        let cell: SnapMusicCell? = tableView.dequeueReusableCell(withIdentifier: CellIdentifier, for: indexPath) as? SnapMusicCell
        return cell ?? SnapMusicCell(style: .default, reuseIdentifier: CellIdentifier)
    }

    func folderCell(tableView: UITableView, indexPath: IndexPath) -> UITableViewCell {
        return tableView.dequeueReusableCell(withIdentifier: FolderCellIdentifier, for: indexPath)
//        return cell ?? UITableViewCell(style: .default, reuseIdentifier: FolderCellIdentifier)
    }
}
