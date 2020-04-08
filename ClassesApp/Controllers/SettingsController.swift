//
//  ProfileController.swift
//  ClassesApp
//
//  Created by Darrel Muonekwu on 3/31/20.
//  Copyright © 2020 Darrel Muonekwu. All rights reserved.
//

import UIKit

class SettingsController: UIViewController {
    
    @IBOutlet weak var tableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationController?.navigationBar.prefersLargeTitles = true
        
        setUpTableView()
    }
    
    /*
     TURN OFF EMAIL NOTIFICAITONS
     VIEW PURCHASE HISTORY
     */
    func setUpTableView(){
        tableView.delegate = self
        tableView.dataSource = self
    }
    
    @IBAction func exitButtonClicked(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
}

extension SettingsController: UITableViewDelegate, UITableViewDataSource{
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 4
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0:
            return 1
        case 1:
            return 3
        case 2:
            return 1
        case 3:
            return 5
        default:
            return 0
        }
        return 1
        
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let row = indexPath.row
        let section = indexPath.section
        
        switch section {
            
        case 0:
            let cell = tableView.dequeueReusableCell(withIdentifier: "TitleCell") as! TitleCell
            cell.titleLabel.text = "Preferences"
            return cell
            
        case 1:
            let cell = tableView.dequeueReusableCell(withIdentifier: "SettingsLabelCell") as! SettingsLabelCell
            switch row {
            case 0:
                cell.titleLabel.text = "Email Preferences"
                return cell
            default:
                return cell
            }
            
        case 2:
            let cell = tableView.dequeueReusableCell(withIdentifier: "TitleCell") as! TitleCell
            cell.titleLabel.text = "Purchase History"
            return cell
        
        case 3:
            let cell = tableView.dequeueReusableCell(withIdentifier: "PurchaseHistoryCell") as! PurchaseHistoryCell
            
            cell.courseTitleCell.text = "34250"
            cell.timeLabel.text = "Tues • 9:15pm"
            cell.priceLabel.text = "$1.49"
            return cell
            
        default:
            return UITableViewCell()
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let row = indexPath.row
        
        switch row {
        case 2:
            return
        default:
            return
        }
    }
}




