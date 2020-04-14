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
        return 4
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0:
            return 1
        case 1:
            return 1
        case 2:
            return 1
        case 3:
            return UserService.user.purchaseHistory.count
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
            let purchase = UserService.user.purchaseHistory.reversed()[row]
            
            cell.courseTitleCell.text = purchase["course_code"]
            cell.timeLabel.text = purchase["date"]?.toDate().toStringInWords()
            cell.priceLabel.text = Int(purchase["price"] ?? "0")?.penniesToFormattedDollars()
            return cell
            
        default:
            return UITableViewCell()
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let row = indexPath.row
        let section = indexPath.section
        print("\(row) \(section)")

        switch section {
        case 1:
            switch row {
            case 0:
                print("clicked")
                let toggleEmailsVC = ToggleEmailsController()
                toggleEmailsVC.modalPresentationStyle = .overFullScreen
                self.present(toggleEmailsVC, animated: true, completion: nil)
                
            default:
                return
            }
            return
        default:
            return
        }
    }
}




