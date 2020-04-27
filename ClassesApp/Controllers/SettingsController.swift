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
    @IBOutlet weak var backgroundView: RoundedView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationController?.navigationBar.prefersLargeTitles = true
        
        setUpTableView()
        setUpGestures()
    }
    
    func setUpTableView(){
        tableView.delegate = self
        tableView.dataSource = self
    }
    
    func setUpGestures() {
        let swipe1: UISwipeGestureRecognizer = UISwipeGestureRecognizer(target: self, action: #selector(self.handleDismiss))
        let swipe2: UISwipeGestureRecognizer = UISwipeGestureRecognizer(target: self, action: #selector(self.handleDismiss))
        swipe1.direction = .down
        swipe2.direction = .down
        backgroundView.addGestureRecognizer(swipe1)
        navigationController?.navigationBar.addGestureRecognizer(swipe2)
    }
    
    @objc func handleDismiss() {
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func exitButtonClicked(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
}

extension SettingsController: UITableViewDelegate, UITableViewDataSource{
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 6
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0: // Account Info
            return 1
        case 1: // Name, Email, School
            return 3
        case 2: // Preferences title
            return 1
        case 3: // Email Preferences, Notifiations
            return 2
        case 4: // Purchase History title
            return 1
        case 5: // Purchase History, Track Classes History
            return 2
        default:
            return 0
        }        
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let row = indexPath.row
        let section = indexPath.section
        
        switch section {
            
        case 0:
            let cell = tableView.dequeueReusableCell(withIdentifier: "TitleCell") as! TitleCell
            cell.titleLabel.text = "Acount Info"
            return cell
            
        case 1:
            let cell = tableView.dequeueReusableCell(withIdentifier: "SettingsLabelCell") as! SettingsLabelCell
            switch row {
            case 0:
                cell.titleLabel.text = "Name"
                cell.infoLabel.text = "\(UserService.user.fullName)"
                return cell
            case 1:
                cell.titleLabel.text = "Email"
                cell.infoLabel.text = "\(UserService.user.email)"
                return cell
            case 2:
                cell.titleLabel.text = "School"
                cell.infoLabel.text = "\(UserService.user.school)"
                return cell
            default:
                return cell
            }
        case 2:
            let cell = tableView.dequeueReusableCell(withIdentifier: "TitleCell") as! TitleCell
            cell.titleLabel.text = "Preferences"
            return cell
            
        case 3:
            let cell = tableView.dequeueReusableCell(withIdentifier: "SettingsLabelCell") as! SettingsLabelCell
            switch row {
            case 0:
                cell.titleLabel.text = "Email Preferences"
                cell.infoLabel.text = ""
                cell.accessoryType = .disclosureIndicator
                cell.selectionStyle = .gray
                return cell
            case 1:
                cell.titleLabel.text = "Notifications"
                cell.infoLabel.text = ""
                cell.accessoryType = .disclosureIndicator
                cell.selectionStyle = .default
                return cell
            default:
                return cell
            }
        case 4:
            let cell = tableView.dequeueReusableCell(withIdentifier: "TitleCell") as! TitleCell
            cell.titleLabel.text = "History"
            return cell
            
        case 5:
            let cell = tableView.dequeueReusableCell(withIdentifier: "SettingsLabelCell") as! SettingsLabelCell
            switch row {
            case 0:
                cell.titleLabel.text = "Purchase History"
                cell.infoLabel.text = ""
                cell.accessoryType = .disclosureIndicator
                cell.selectionStyle = .gray
                return cell
            case 1:
                cell.titleLabel.text = "Tracked Classes History"
                cell.infoLabel.text = ""
                cell.accessoryType = .disclosureIndicator
                cell.selectionStyle = .default
                return cell
            default:
                return cell
            }
        default:
            return UITableViewCell()
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let row = indexPath.row
        let section = indexPath.section
        
        switch section {
        case 3:
            print("clicked \(row) \(section)")
            tableView.deselectRow(at: indexPath, animated: true)
            switch row {
            case 0:
                let toggleEmailsVC = ToggleEmailsController()
                toggleEmailsVC.modalPresentationStyle = .overFullScreen
                self.present(toggleEmailsVC, animated: true, completion: nil)
            case 1:
                let notifStatusVC = NotifcationStatusController()
                notifStatusVC.modalPresentationStyle = .overFullScreen
                self.present(notifStatusVC, animated: true, completion: nil)
            default:
                return
            }
        case 5:
            tableView.deselectRow(at: indexPath, animated: true)
            switch row {
            case 0: // Purchase History
                let historyVC = storyboard?.instantiateViewController(withIdentifier: "HistoryController") as! HistoryController
                historyVC.modalPresentationStyle = .overFullScreen
                historyVC.presentPurchaseHist = true
                self.present(historyVC, animated: true, completion: nil)
            case 1: // Tracked Classes History
                let historyVC = storyboard?.instantiateViewController(withIdentifier: "HistoryController") as! HistoryController
                historyVC.modalPresentationStyle = .overFullScreen
                historyVC.presentPurchaseHist = false
                self.present(historyVC, animated: true, completion: nil)
            default:
                break
            }
            return
        default:
            return
        }
    }
}




