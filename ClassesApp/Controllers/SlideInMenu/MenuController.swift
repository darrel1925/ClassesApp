//
//  MenuController.swift
//  ClassesApp
//
//  Created by Darrel Muonekwu on 3/30/20.
//  Copyright © 2020 Darrel Muonekwu. All rights reserved.
//

import UIKit

enum MenuType: Int {
    case Title
    case Notifications
    case Premium
    case Settings
    case Share
    case HowItWorks
    case Support
    case Logout
    case Credits
}

class MenuController: UITableViewController {
    // capture the menue type and pass it to our HomeViewController
    var didTapMenuType: ((MenuType) -> Void)?
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 9
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    
        tableView.deselectRow(at: indexPath, animated: true)
        guard let menuType = MenuType(rawValue: indexPath.row) else { return }
        dismiss(animated: true) { [weak self] in
            print("Dismissing \(menuType)")
            self?.didTapMenuType?(menuType)            
        }
        return
    }

    @IBAction func creditsButtonClicked(_ sender: Any) {
        dismiss(animated: true) { [weak self] in
            print("Dismissing Credits")
            self?.didTapMenuType?(MenuType.Credits)
        }
    }
}
