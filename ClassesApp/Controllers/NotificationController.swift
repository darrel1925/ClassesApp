//
//  NotificationController.swift
//  ClassesApp
//
//  Created by Darrel Muonekwu on 4/6/20.
//  Copyright © 2020 Darrel Muonekwu. All rights reserved.
//

import UIKit
import FirebaseFirestore

class NotificationController: UIViewController {
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var backgroundView: RoundedView!
    
    var noClassLabel: UILabel!
    var refreshControl: UIRefreshControl?
    var labelHasBeenPresented: Bool = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationController?.navigationBar.prefersLargeTitles = true
        
        addLabel()
        setUpTableView()
        setUpGestures()
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
    
    func setUpGestures() {
        let swipe1: UISwipeGestureRecognizer = UISwipeGestureRecognizer(target: self, action: #selector(self.handleDismiss))
        let swipe2: UISwipeGestureRecognizer = UISwipeGestureRecognizer(target: self, action: #selector(self.handleDismiss))
        swipe1.direction = .down
        swipe2.direction = .down
        backgroundView.addGestureRecognizer(swipe1)
        navigationController?.navigationBar.addGestureRecognizer(swipe2)
    }

    func displayClearNotificationsAlert() {

        let alert = UIAlertController(title: "Clear Notifications", message: "", preferredStyle: .alert)
        let clearAction = UIAlertAction(title: "Clear", style: .default, handler: {_ in             self.clearNotifications()
        })
        let cancelAction = UIAlertAction(title: "Cancel", style: .default, handler: nil)
        
        alert.addAction(cancelAction)
        alert.addAction(clearAction)
        present(alert, animated: true, completion: nil)
        
    }
    
    func addLabel() {
        guard let window = UIApplication.shared.keyWindow else { return }

        noClassLabel = UILabel(frame: CGRect(x: 0, y: 0, width: 250, height: 350))
        noClassLabel.font = UIFont(name: "Futura", size: 20.0)
        noClassLabel.center = window.center
        noClassLabel.textAlignment = .center
        noClassLabel.text = "No new notifications. Check in again later or pull down to refresh!"
        noClassLabel.numberOfLines = 3
        
        noClassLabel.center = self.view.center
        noClassLabel.center.x = self.view.center.x
        noClassLabel.center.y = self.view.center.y
        
        labelHasBeenPresented = true

        self.view.addSubview(noClassLabel)
    }
    
    func toggleNoClassLabel(){
        let notifs = UserService.user.notifications
        if notifs.count > 0 && notifs != [[:]] {

            self.noClassLabel.isHidden = true
        }
        else {
            
            if !self.labelHasBeenPresented { self.addLabel() }
            self.noClassLabel.isHidden = false
        }
    }
    
    @objc func handleDismiss() {
        dismiss(animated: true, completion: nil )
    }
    
    @objc func refreshTableView() {
        toggleNoClassLabel()
        tableView.reloadData()
        self.refreshControl?.endRefreshing()
        
    }
    
    @IBAction func exitButtonClicked(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func clearButtonClicked(_ sender: Any) {
        displayClearNotificationsAlert()
    }
}

extension NotificationController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        print("NOTIFS \(UserService.user.notifications)")
        return UserService.user.notifications.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let row = indexPath.row
        let notification = UserService.user.revNotifications[row]
        let cell = tableView.dequeueReusableCell(withIdentifier: "NotificationCell") as! NotificationCell

        cell.selectionStyle = .none
        cell.courseNumberLabel.text = notification[DataBase.name]
        cell.courseDescriptionLabel.text = "Status changed from \(notification[DataBase.old_status] ?? "") to \(notification[DataBase.new_status] ?? "")"
        
        cell.timeLabel.text = notification[DataBase.date]?.toDate().toStringInWords()
        
        return cell
    }
    
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            removeNotification(AtIndex: indexPath.row)
            self.tableView.deleteRows(at: [indexPath], with: .automatic)
            print("Deleted")
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 70
    }
    
    func removeNotification(AtIndex index: Int) {
        let dispatchGroup = DispatchGroup()
        let db = Firestore.firestore()
        dispatchGroup.enter()
        
        let docRef = db.collection(DataBase.User).document(UserService.user.email)
        
        var updatedNotifications = UserService.user.notifications
        updatedNotifications.remove(at: index)
        UserService.user.notifications = updatedNotifications
        
        docRef.updateData([DataBase.notifications : updatedNotifications]) { (error) in
            if let _ = error {
                print("could not update notificaitons")
                dispatchGroup.customLeave()
                return
            }
            print("notificaitons updated")
            self.toggleNoClassLabel()
            dispatchGroup.customLeave()
        }
    }
    
    func clearNotifications() {
        let dispatchGroup = DispatchGroup()
        let db = Firestore.firestore()
        dispatchGroup.enter()
        
        let docRef = db.collection(DataBase.User).document(UserService.user.email)
                
        docRef.updateData([DataBase.notifications : []]) { (error) in
            if let _ = error {
                dispatchGroup.customLeave()
                return
            }
            UserService.user.notifications = []
            self.tableView.reloadData()
            dispatchGroup.customLeave()
            self.toggleNoClassLabel()
        }
    }
}
