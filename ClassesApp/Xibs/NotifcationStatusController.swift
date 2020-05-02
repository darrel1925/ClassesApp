//
//  NotifcationStatusController.swift
//  ClassesApp
//
//  Created by Darrel Muonekwu on 4/23/20.
//  Copyright © 2020 Darrel Muonekwu. All rights reserved.
//

import UIKit
import FirebaseFirestore

class NotifcationStatusController: UIViewController {
    
    @IBOutlet weak var backgroundView: UIView!
    @IBOutlet weak var containerView: RoundedView!
    @IBOutlet weak var descriptionLabel: UILabel!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var notificationButton: UIButton!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    var willRecieveNotifs = UserService.user.notificationsEnabled
    
    override func viewDidLoad() {
        super.viewDidLoad()
        notificationButton.layer.cornerRadius = 20
        notificationButton.isHidden = true
        setLabels()
        setUpGestures()
        animateViewDownward()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        animateViewUpwards()
    }
    
    
    func setUpGestures() {
        backgroundView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(handleDismiss)))
        
        let swipe: UISwipeGestureRecognizer = UISwipeGestureRecognizer(target: self, action: #selector(handleDismiss))
        swipe.direction = .down
        backgroundView.addGestureRecognizer(swipe)
    }
    
    func setLabels() {
        var showSetUp = false
        let dg = DispatchGroup()
        dg.enter()
        
        if #available(iOS 10.0, *) {
            let current = UNUserNotificationCenter.current()
            current.getNotificationSettings(completionHandler: { settings in
                switch settings.authorizationStatus {
                case .notDetermined:
                    break
                case .denied: // User has denied authorization.
                    break
                case .authorized: // User has given authorization.
                    print("is authorized")
                    showSetUp = true
                case .provisional: // idk
                    showSetUp = true
                @unknown default:
                    showSetUp = true
                }
                dg.leave()
            })
        }
            
        else {
            // Fallback on earlier versions
            if UIApplication.shared.isRegisteredForRemoteNotifications {
                showSetUp = true
            }
            dg.leave()
        }
        
        dg.notify(queue: .main) {
            if showSetUp {
                self.notificationButton.isHidden = false
                self.setButton()
            }
            else {
                self.titleLabel.text = "Notifications Are Disabled"
                self.descriptionLabel.text = "To enable push notifications for this device go to Settings → TrackMy → Notifications then press 'Allow Notifications.'"
            }
        }
    }
    
    func animateViewUpwards() {
        guard let window = UIApplication.shared.keyWindow else { return }
        
        let height: CGFloat = 225
        let y = window.frame.height - height
        
        UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 1, options: .curveEaseOut, animations: {
            
            self.backgroundView.alpha = 0.5
            self.containerView.frame = CGRect(x: 0, y: y, width: window.frame.width, height: height)
            
        }, completion: nil)
    }
    
    func animateViewDownward() {
        backgroundView.alpha = 0
        guard let window = UIApplication.shared.keyWindow else { return }
        containerView.frame = CGRect(x: 0, y: window.frame.height, width: window.frame.width, height: 0)
    }
    
    
    func setButton() {
        if self.willRecieveNotifs {
            self.notifsOn()
        }
        else {
            self.notifsOff()
        }
    }
    
    func notifsOn() {
        self.notificationButton.backgroundColor = #colorLiteral(red: 0.762566535, green: 0.3093850772, blue: 0.2170317457, alpha: 1)
        self.notificationButton.setTitle("Stop receiving notifications", for: .normal)
        self.titleLabel.text = "Push Notifications On"
        self.descriptionLabel.text = "Click below to stop receiving push notifications on this account. (Not Recommended)"
    }
    
    func notifsOff() {
        self.notificationButton.backgroundColor = #colorLiteral(red: 0.3260789019, green: 0.5961753091, blue: 0.1608898185, alpha: 1)
        self.notificationButton.setTitle("Begin receiving notifications", for: .normal)
        self.titleLabel.text = "Push Notifications Off"
        self.descriptionLabel.text = "Click below to begin receiving push notifications on this account. (Recommended)"
    }
    
    func updateDataBase() {
        let dg = DispatchGroup()
        
        getNotifPreference(dispatchGroup: dg)
        dg.notify(queue: .main) {
            self.setButton()
        }
    }
    
    func getNotifPreference(dispatchGroup dg: DispatchGroup) {
        dg.enter()
        let db = Firestore.firestore()
        let docRef = db.collection(DataBase.User).document(UserService.user.email)
        activityIndicator.startAnimating()
        print("clicked 2")
        
        if self.willRecieveNotifs {
            docRef.updateData([DataBase.notifications_enabled : false]) { (err) in
                if let _ = err {
                    print("couldnt set to falase!")
                    self.activityIndicator.stopAnimating()
                    dg.leave()
                    return
                }
                print("success set to false")
                self.activityIndicator.stopAnimating()
                self.willRecieveNotifs = false
                dg.leave()
            }
        }
        else {
            docRef.updateData([DataBase.notifications_enabled : true]) { (err) in
                if let _ = err {
                    print("couldnt set to true!")
                    self.activityIndicator.stopAnimating()
                    dg.leave()
                    return
                }
                print("success true")
                dg.leave()
                self.activityIndicator.stopAnimating()
                self.willRecieveNotifs = true
            }
        }
    }
    
    @objc func handleDismiss() {
        
        UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 1, options: .curveEaseOut, animations: {
            
            self.view.alpha = 0
            
        }, completion: {_ in
            UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 1, options: .curveEaseOut, animations: {
                
                self.dismiss(animated: true, completion: nil)
                
            }, completion: nil)
        })
    }
    
    @IBAction func notificationButton(_ sender: Any) {
        print("clicked 1")
        updateDataBase()
    }
}
