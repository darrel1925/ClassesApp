//
//  HomePageController.swift
//  ClassesApp
//
//  Created by Darrel Muonekwu on 3/25/20.
//  Copyright © 2020 Darrel Muonekwu. All rights reserved.
//

import UIKit
import FirebaseAuth
import FirebaseFirestore
import MessageUI

class HomePageController: UIViewController {
    
    @IBOutlet weak var quarterLabel: UILabel!
    @IBOutlet weak var backgroundView: RoundedView!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var leftForegroundView: UIView!
    
    let addClassLauncher = AddClassLauncher()
    let transition = SlideInTransition()
    
    var noClassLabel: UILabel!
    var addClassesisPresented = false
    var labelHasBeenPresented = false
    var refreshControl: UIRefreshControl?
    var courseCodes = [String]()
    var courseStatus = [String]()
    
    var lastClick: TimeInterval!
    var lastIndexPath: IndexPath!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        quarterLabel.text = "\(AppConstants.quarter.capitalizingFirstLetter()) \(AppConstants.year.capitalizingFirstLetter())"
        
        addLabel()
        setUpNavController()
        setUpTableView()
        setUpGestures()
        UserService.generateReferralLink()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        refreshTableView()
        addClassesisPresented = false
    }
    
    func setUpGestures() {
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(didSwipeOnView))
        leftForegroundView.addGestureRecognizer(panGesture)
    }
    
    func setUpTableView() {
        self.tableView.delegate = self
        self.tableView.dataSource = self
        refreshControl = UIRefreshControl()
        refreshControl?.tintColor = .black
        refreshControl?.addTarget(self, action: #selector(refreshTableView), for: .valueChanged)
        tableView.addSubview(refreshControl!)
        
        toggleNoClassLabel()
    }
    
    func setUpNavController() {
        self.navigationController?.navigationBar.tintColor = .black
        
        self.navigationItem.largeTitleDisplayMode = .always
        self.navigationController?.navigationBar.prefersLargeTitles = true
    }
    
    func presentSplashScreen() {
        let vc = storyboard?.instantiateViewController(withIdentifier: "SplashScreenController") as! SplashScreenController
        vc.modalPresentationStyle = .fullScreen //or .overFullScreen for transparency
        self.present(vc, animated: true, completion: nil)
    }
    
    func presentLogoutAlert() {
        let message = "Are you sure you would like to log out?"
        
        let alert = UIAlertController(title: "Logout", message: message, preferredStyle: .alert)
        let cancelAction = UIAlertAction(title: "Cancel", style: .default, handler: nil)
        let logoutAction = UIAlertAction(title: "Logout", style: .default, handler: {_ in
            self.logOut()
        })
        
        alert.addAction(cancelAction)
        alert.addAction(logoutAction)
        
        self.present(alert, animated: true, completion: nil)
    }
    
    func presentDeleteAlert(atIndexPath indexPath: IndexPath) {
        let message = "Are you sure you would like to remove \(courseCodes[indexPath.row])? \n\nYou will be able to track this course again for the rest of the term for no additional cost."
        
        let alert = UIAlertController(title: "Delete \(self.courseCodes[indexPath.row])", message: message, preferredStyle: .alert)
        let cancelAction = UIAlertAction(title: "Cancel", style: .default, handler: nil)
        let deleteAction = UIAlertAction(title: "Delete", style: .default, handler: {_ in
            print("Deleted")
            ServerService.removeClassesFromFirebase(withClasses: [self.courseCodes[indexPath.row]])
            self.courseCodes.remove(at: indexPath.row)
            self.courseStatus.remove(at: indexPath.row)
            self.tableView.deleteRows(at: [indexPath], with: .automatic)
        })
        
        alert.addAction(cancelAction)
        alert.addAction(deleteAction)
        
        self.present(alert, animated: true, completion: nil)
    }
    
    func presentNotifications() {
        let vc = storyboard?.instantiateViewController(withIdentifier: "NotificationController") as! NotificationController
        let navController = UINavigationController(rootViewController: vc)
        navController.modalPresentationStyle = .fullScreen
        self.present(navController, animated: true, completion: nil)
    }
    
    func presentSettings() {
        let vc = storyboard?.instantiateViewController(withIdentifier: "SettingsController") as! SettingsController
        let navController = UINavigationController(rootViewController: vc)
        navController.modalPresentationStyle = .fullScreen
        self.present(navController, animated: true, completion: nil)
    }
    
    func presentStore() {
        let vc = storyboard?.instantiateViewController(withIdentifier: "StoreController") as! StoreController
        let navController = UINavigationController(rootViewController: vc)
        navController.modalPresentationStyle = .fullScreen
        self.present(navController, animated: true, completion: nil)
    }
    
    func presentAddClassesController() {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: "AddClassController") as! AddClassController
        navigationController?.pushViewController(vc, animated: true)
    }
    
    func presentShareController() {
        let shareStr = "URL for appl download goes here :p"
        let sharingController = UIActivityViewController(activityItems: [shareStr], applicationActivities: nil)
        self.present(sharingController, animated: true, completion: nil)
    }
    
    func presentHowItWorks() {
        let vc = storyboard?.instantiateViewController(withIdentifier: "PageController") as! PageController
        vc.modalPresentationStyle = .fullScreen
        self.present(vc, animated: true, completion: nil)
    }
    
    func presentSupportOrFeedBack(){
        let message = "Your sending your Feeback or seeking Support?"
        let alert = UIAlertController(title: "Feedback or Support", message: message, preferredStyle: .alert)
        let feebackAction = UIAlertAction(title: "Feeback", style: .default, handler: {_ in
            self.presentSupport(emailType: "Feedback")
        })
        let supportAction = UIAlertAction(title: "Support", style: .default, handler: {_ in
            self.presentSupport(emailType: "Support")
        })
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        
        alert.addAction(feebackAction)
        alert.addAction(supportAction)
        alert.addAction(cancelAction)
        present(alert, animated: true, completion: nil)
    }
    
    func presentSupport(emailType: String) {
        guard MFMailComposeViewController.canSendMail() else {
            let message = "Email account not set up on this device. Head over to Setting → Passwords&Accounts → Add Account, then add your email address. You can also send an email to \(AppConstants.support_email)"
            self.displayError(title: "Cannot Send Mail", message: message)
            return
        }
        
        let composer = MFMailComposeViewController()
        composer.mailComposeDelegate = self
        composer.setSubject(emailType)
        composer.setToRecipients([AppConstants.support_email])
        
        present(composer, animated: true)
    }
    
    func presentCredits() {
        let vc = storyboard?.instantiateViewController(withIdentifier: "CreditsController") as! CreditsController
        let navController = UINavigationController(rootViewController: vc)
        navController.modalPresentationStyle = .fullScreen
        self.present(navController, animated: true, completion: nil)
    }
    
    func toggleNoClassLabel(){
        if self.courseCodes.count > 0 {
            self.noClassLabel.isHidden = true
        }
        else {
            if !self.labelHasBeenPresented { self.addLabel() }
            self.noClassLabel.isHidden = false
        }
    }
    
    func addLabel() {
        guard let window = UIApplication.shared.keyWindow else { return }
        
        noClassLabel = UILabel(frame: CGRect(x: 0, y: 0, width: 250, height: 350))
        noClassLabel.font = UIFont(name: "Futura", size: 20.0)
        noClassLabel.center = window.center
        noClassLabel.textAlignment = .center
        noClassLabel.text = "You aren't tracking any classes yet. Click below to get started!"
        noClassLabel.numberOfLines = 3
        
        noClassLabel.center = self.view.center
        noClassLabel.center.x = self.view.center.x
        noClassLabel.center.y = self.view.center.y
        
        labelHasBeenPresented = true
        
        self.view.addSubview(noClassLabel)
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
            catch let signOutError as NSError {
                print ("Error signing out: %@", signOutError)
                return
            }
        }
        else { // if user is not signed in
            print("user not signed in")
            presentSplashScreen()
        }
    }
    
    func slideInMenu() {
        guard let menuVC = storyboard?.instantiateViewController(identifier: "MenuController") as? MenuController else { return }
        menuVC.didTapMenuType = { menuType in
            // functions here
            let menuTypeString = String(describing: menuType)
            
            switch menuTypeString {
            case "Logout":
                self.presentLogoutAlert()
                
            case "Notifications":
                self.presentNotifications()
                
            case "Settings":
                self.presentSettings()
                
            case "Store":
                self.presentStore()
                
            case "HowItWorks":
                self.presentHowItWorks()
                
            case "Share":
                self.presentShareController()
                
            case "Support":
                self.presentSupportOrFeedBack()
                
            case "Credits":
                self.presentCredits()
                
            default:
                print("here")
                return
            }
        }
        menuVC.modalPresentationStyle = .overCurrentContext
        menuVC.transitioningDelegate = self
        present(menuVC, animated: true, completion: nil)
    }
    
    @objc func refreshTableView() {
        let dispatchGroup = DispatchGroup()
        courseCodes.removeAll()
        courseStatus.removeAll()
        ServerService.getClassStatus(withGroup:dispatchGroup, homeVC: self)
        
        
        dispatchGroup.notify(queue: .main) {
            print("reloading")
            self.refreshControl?.endRefreshing()
            self.tableView.reloadData()
            self.toggleNoClassLabel()
        }
    }
    
    @objc func didSwipeOnView(gestureRecognizer: UIPanGestureRecognizer) {
        // Swiping from left to right
        if case .Right = gestureRecognizer.horizontalDirection(target: self.view)  {
            slideInMenu()
        }
        else { // Swiping from right to left
            if addClassesisPresented { return }
            
            //            presentAddClassesController()
            addClassesisPresented = true
        }
    }
    
    @IBAction func addClassClicked(_ sender: Any) {
        presentAddClassesController()
    }
    
    
    @IBAction func menuClicked(_ sender: Any) {
        slideInMenu()
    }
}


extension HomePageController:  UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.courseCodes.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let row = indexPath.row
        let cell = tableView.dequeueReusableCell(withIdentifier: "TrackedCell") as! TrackedCell
        
        cell.courseCodeLabel.text = self.courseCodes[row]
        cell.statusLabel.text = self.courseStatus[row]
        cell.cellView.layer.cornerRadius = 5
        updateUI(withCell: cell, withResponce: self.courseStatus[row])
        return cell
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            self.presentDeleteAlert(atIndexPath: indexPath)
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let now: TimeInterval = Date().timeIntervalSince1970
        if self.lastClick == nil {
            self.lastClick = now
            self.lastIndexPath = indexPath
            return
        }
        
        if (now - self.lastClick < 0.4) && (self.lastIndexPath?.row == indexPath.row )
        {
            self.presentDeleteAlert(atIndexPath: indexPath)
        }
        self.lastClick = now
        self.lastIndexPath = indexPath

    }
    
    func updateUI(withCell cell: TrackedCell, withResponce response: String) {
        print("got response \(response)")
        switch response {
        case Response.OPEN:
            cell.cellView.backgroundColor = #colorLiteral(red: 0.4574845033, green: 0.8277172047, blue: 0.4232197912, alpha: 0.2520467252)
            return
        case Response.Waitl:
            cell.cellView.backgroundColor = #colorLiteral(red: 0.8425695398, green: 0.8208485929, blue: 0, alpha: 0.248053115)
            return
        case Response.FULL:
            cell.cellView.backgroundColor = #colorLiteral(red: 0.8103429773, green: 0.08139390926, blue: 0.116439778, alpha: 0.2456195088)
            return
        case Response.NewOnly:
            cell.cellView.backgroundColor = #colorLiteral(red: 0, green: 0.6157837616, blue: 0.9281850962, alpha: 0.2466803115)
            return
        default:
            cell.cellView.backgroundColor = #colorLiteral(red: 0.505957987, green: 0.01517132679, blue: 0.8248519059, alpha: 0.2461187101)
            return
        }
    }
}

extension HomePageController: UIViewControllerTransitioningDelegate {
    func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        transition.isPresenting = true
        return transition
    }
    
    func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        transition.isPresenting = false
        return transition
    }
}

extension HomePageController: UIGestureRecognizerDelegate {
    
    //    private func gestureRecognizer(gestureRecognizer: UIGestureRecognizer, shouldReceiveTouch touch: UITouch) -> Bool {
    //        if touch.view?.isDescendant(of: self.tableView) == true {
    //        return false
    //    }
    //    return true
    //    }
}

extension HomePageController: MFMailComposeViewControllerDelegate {
    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        
        if error != nil {
            controller.displaySimpleError(title: "Could Not Send Email", message: "Could not send you email. You can also send an email to \(AppConstants.support_email).", completion: {_ in
                controller.dismiss(animated: true, completion: nil)
            })
            return
        }
        
        switch result{
        case .cancelled:
            controller.dismiss(animated: true, completion: nil)
        case .saved:
            print("saved")
            controller.displaySimpleError(title: "Email Saved", message: "Your email has been saved to your drafts.", completion: {_ in
                controller.dismiss(animated: true, completion: nil)
            })
        case .sent:
            controller.displaySimpleError(title: "Email Sent", message: "Your email has sent successfully!", completion: {_ in
                controller.dismiss(animated: true, completion: nil)
            })
            print("sent")
        case .failed:
            controller.displaySimpleError(title: "Error", message: "Could not send you email. You can also send an email to \(AppConstants.support_email)", completion: {_ in
                controller.dismiss(animated: true, completion: nil)
            })
            print("failed")
        @unknown default:
            controller.dismiss(animated: true, completion: nil)
            print("unkown")
        }
    }
}

