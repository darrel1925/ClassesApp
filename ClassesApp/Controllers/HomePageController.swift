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

class HomePageController: UIViewController, UITextFieldDelegate {
    
    @IBOutlet weak var backgroundView: RoundedView!
    @IBOutlet weak var tableView: UITableView!
    
    let addClassLauncher = AddClassLauncher()
    let transition = SlideInTransition()
    
    var noClassLabel: UILabel!
    var labelHasBeenPresented = false
    var refreshControl: UIRefreshControl?
    var courseCodes = [String]()
    var courseStatus = [String]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        print("headerText has been updated")
        print("Classes are \(UserService.user.classes)")
        addLabel()
        setUpNavController()
        setUpTableView()
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
    
    func getClassStatus(withGroup dispatchGroup: DispatchGroup) {
        let db = Firestore.firestore()
        courseCodes.removeAll()
        courseStatus.removeAll()
        for cls in UserService.user.classArr {
            dispatchGroup.enter()
            let docRef = db.collection("Class").document("\(cls) spring")
            
            docRef.getDocument { (document, error) in
                if let document = document, document.exists {
                    guard let data = document.data() else { print("couldn't do it"); return }
                    let status = data["curr_status"] as! String
                    self.courseCodes.append(cls)
                    self.courseStatus.append(status)
                    
                    print("Found course: \(cls) status: \(data["curr_status"])")
                    dispatchGroup.leave()
                    
                } else {
                    print("Document does not exist")
                    dispatchGroup.leave()
                }
            }
        }
    }
    @objc func refreshTableView() {
        let dispatchGroup = DispatchGroup()
        getClassStatus(withGroup: dispatchGroup)
        
        dispatchGroup.notify(queue: .main) {
            print("reloading")
            self.refreshControl?.endRefreshing()
            self.tableView.reloadData()
            
            self.toggleNoClassLabel()
            
        }
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
    
    func setUpTableView() {
        self.tableView.delegate = self
        self.tableView.dataSource = self
        refreshControl = UIRefreshControl()
        refreshControl?.tintColor = .black
        refreshControl?.addTarget(self, action: #selector(refreshTableView), for: .valueChanged)
        tableView.addSubview(refreshControl!)
        
        let dispatchGroup = DispatchGroup()
        
        getClassStatus(withGroup: dispatchGroup)
        
        dispatchGroup.notify(queue: .main) {
            print("reloading")
            print("course codes \(self.courseCodes)")
            self.tableView.reloadData()
            
            self.toggleNoClassLabel()
        }
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
        
        alert.addAction(logoutAction)
        alert.addAction(cancelAction)
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
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        self.view.endEditing(true)
        return false
    }
    
    func logOut() {
        // if user is signed in
        if let _ = Auth.auth().currentUser {
            do {
                try Auth.auth().signOut()
                UserService.logoutUser()
                print("sign out successful")
                presentSplashScreen()
            }
            catch let signOutError as NSError {
                print ("Error signing out: %@", signOutError)
                return
            }
        }
            // if user is not signed in
        else {
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
            default:
                return
            }
        }
        menuVC.modalPresentationStyle = .overCurrentContext
        menuVC.transitioningDelegate = self
        present(menuVC, animated: true, completion: nil)
    }
    
    @IBAction func addClassClicked(_ sender: Any) {
    }
    
    
    @IBAction func menuClicked(_ sender: Any) {
        slideInMenu()
        return
        
    }
}


extension HomePageController:  UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.courseCodes.count + 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let row = indexPath.row
        let index = row - 1
        let cell = tableView.dequeueReusableCell(withIdentifier: "TrackedCell") as! TrackedCell
        
        if row == 0 {
            cell.courseCodeLabel.text = "Course Code"
            cell.statusLabel.text = "Status"
            return cell
        }
        
        print("type = \(type(of: self.courseCodes[index])) \(self.courseCodes[index])")
        cell.courseCodeLabel.text = self.courseCodes[index]
        cell.statusLabel.text = self.courseStatus[index]
        updateUI(withCell: cell, withResponce: self.courseStatus[index])
        return cell
    }
    
    func updateUI(withCell cell: TrackedCell, withResponce response: String) {
        print("got response \(response)")
        switch response {
        case "OPEN":
            cell.cellView.backgroundColor = #colorLiteral(red: 0.4574845033, green: 0.8277172047, blue: 0.4232197912, alpha: 0.2520467252)
            return
        case "Waitl":
            cell.cellView.backgroundColor = #colorLiteral(red: 0.8425695398, green: 0.8208485929, blue: 0, alpha: 0.248053115)
            return
        case "FULL":
            cell.cellView.backgroundColor = #colorLiteral(red: 0.8103429773, green: 0.08139390926, blue: 0.116439778, alpha: 0.2456195088)
            return
        case "NewOnly":
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
