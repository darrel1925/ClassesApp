//
//  ProfileController.swift
//  ClassesApp
//
//  Created by Darrel Muonekwu on 3/31/20.
//  Copyright © 2020 Darrel Muonekwu. All rights reserved.
//

import UIKit
import FirebaseAuth

class SettingsController: UIViewController {
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var backgroundView: RoundedView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationController?.navigationBar.prefersLargeTitles = true
        
        setUpTableView()
        setUpGestures()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        tableView.reloadData() // incase they update their school
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
    
    
    func presentTermsController() {
        let vc = storyboard?.instantiateViewController(withIdentifier: "TermsController") as! TermsController
        let navController = UINavigationController(rootViewController: vc)
        navController.modalPresentationStyle = .fullScreen
        self.present(navController, animated: true, completion: nil)
    }
    
    func presentPrivacyController() {
        let vc = storyboard?.instantiateViewController(withIdentifier: "PrivacyController") as! PrivacyController
        let navController = UINavigationController(rootViewController: vc)
        navController.modalPresentationStyle = .fullScreen
        self.present(navController, animated: true, completion: nil)
    }
    
    func presentSplashScreen() {
        let vc = storyboard?.instantiateViewController(withIdentifier: "SplashScreenController") as! SplashScreenController
        vc.modalPresentationStyle = .fullScreen //or .overFullScreen for transparency
        self.present(vc, animated: true, completion: nil)
    }

    func presentForgotPassword() {
        let forgotPassVC = ForgotPasswordController()
        forgotPassVC.modalTransitionStyle = .crossDissolve
        forgotPassVC.modalPresentationStyle = .overCurrentContext
        present(forgotPassVC, animated: true, completion: nil)
    }
    
    func presentLogOutAlert() {
        let message = "Are you sure you would like to log out?"
        
        let alert = UIAlertController(title: "Log out", message: message, preferredStyle: .alert)
        let cancelAction = UIAlertAction(title: "Cancel", style: .default, handler: nil)
        let logOutAction = UIAlertAction(title: "Log out", style: .default, handler: {_ in
            self.logOut()
        })
        
        alert.addAction(cancelAction)
        alert.addAction(logOutAction)
        
        self.present(alert, animated: true, completion: nil)
    }
    
    func logOut() {
         // if user is signed in
         if let _ = Auth.auth().currentUser {
             do {
                 try Auth.auth().signOut()
                 let dg = DispatchGroup()
                 UserService.logoutUser(disaptchGroup: dg)
                 print("sign out successful")
                 dg.notify(queue: .main) {
                     self.presentSplashScreen()
                 }
             }
             catch _ as NSError {
                displayError(title: "Error Signing Out", message: "If this problem continues, please contact support.")
                 return
             }
         }
         else { // if user is not signed in
             print("user not signed in")
             presentSplashScreen()
         }
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
        return 8
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0: // Account Info
            return 1
        case 1: // Email, School, Change Password
            return 3
        case 2: // Preferences title
            return 1
        case 3: // Email Preferences, Notifiations
            return 2
        case 4: // Legal
            return 1
        case 5: // Privacy Policy, Terms and Agreements
            return 2
        case 6: // Logout
            return 1
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
                cell.titleLabel.text = "Email"
                cell.infoLabel.text = "\(UserService.user.email)"
                return cell
            case 1:
                cell.titleLabel.text = "School"
                cell.infoLabel.text = "\(UserService.user.school)"
                cell.accessoryType = .disclosureIndicator
                cell.selectionStyle = .gray
                return cell
            case 2:
                cell.titleLabel.text = "Change Password"
                cell.infoLabel.text = ""
                cell.accessoryType = .disclosureIndicator
                cell.selectionStyle = .gray
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
                cell.selectionStyle = .gray
                return cell
            default:
                return cell
            }
        case 4:
            let cell = tableView.dequeueReusableCell(withIdentifier: "TitleCell") as! TitleCell
            cell.titleLabel.text = "Legal"
            return cell
            
        case 5:
            let cell = tableView.dequeueReusableCell(withIdentifier: "SettingsLabelCell") as! SettingsLabelCell
            switch row {
            case 0:
                cell.titleLabel.text = "Privacy Policy"
                cell.infoLabel.text = ""
                cell.accessoryType = .disclosureIndicator
                cell.selectionStyle = .gray
                return cell
            case 1:
                cell.titleLabel.text = "Terms and Agreements"
                cell.infoLabel.text = ""
                cell.accessoryType = .disclosureIndicator
                cell.selectionStyle = .gray
                return cell
            default:
                return cell
            }
        case 6:
            let cell = tableView.dequeueReusableCell(withIdentifier: "TitleCell") as! TitleCell
            cell.titleLabel.text = "Log out"
            cell.titleLabel?.textColor = #colorLiteral(red: 0.762566535, green: 0.3093850772, blue: 0.2170317457, alpha: 1)

            cell.accessoryType = .disclosureIndicator
            cell.selectionStyle = .default
            return cell
        default:
            return UITableViewCell()
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let row = indexPath.row
        let section = indexPath.section
        tableView.deselectRow(at: indexPath, animated: true)
        switch section {
        case 1:
            switch row {
            case 1:
                let changeSchoolVC = ChangeSchoolController()
                changeSchoolVC.modalPresentationStyle = .overFullScreen
                changeSchoolVC.settingsVC = self
                self.present(changeSchoolVC, animated: true, completion: nil)
                return
            case 2:
                presentForgotPassword()
                return
            default:
                return
            }
        case 3:
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
            switch row {
            case 0: // Privacy Policy
                presentPrivacyController()
            case 1: // Terms and Agreements
                presentTermsController()
            default:
                break
            }
        case 6: // Logout
            presentLogOutAlert()
        default:
            return
        }
    }
}



