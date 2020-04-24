//
//  ToggleEmailsController.swift
//  ClassesApp
//
//  Created by Darrel Muonekwu on 4/10/20.
//  Copyright © 2020 Darrel Muonekwu. All rights reserved.
//

import UIKit
import FirebaseFirestore

class ToggleEmailsController: UIViewController {
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var descriptionLabel: UILabel!
    @IBOutlet weak var emailButton: RoundedButton!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var containerView: RoundedView!
    @IBOutlet weak var backgroundView: UIView!
    
    
    var willRecieveEmails = UserService.user.receiveEmails
    
    override func viewDidLoad() {
        super.viewDidLoad()
        emailButton.layer.cornerRadius = 20
        setButton()
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
    
    
    func getEmailPreference(dispatchGroup dg: DispatchGroup) {
        dg.enter()
        let db = Firestore.firestore()
        let docRef = db.collection(DataBase.User).document(UserService.user.email)
        activityIndicator.startAnimating()
        
        
        if self.willRecieveEmails {
            docRef.updateData([DataBase.receive_emails : false]) { (err) in
                if let _ = err {
                    print("couldnt set to falase!")
                    self.activityIndicator.stopAnimating()
                    dg.leave()
                    return
                }
                print("success set to false")
                self.activityIndicator.stopAnimating()
                self.willRecieveEmails = false
                dg.leave()
            }
        }
        else {
            docRef.updateData([DataBase.receive_emails : true]) { (err) in
                if let _ = err {
                    print("couldnt set to true!")
                    self.activityIndicator.stopAnimating()
                    dg.leave()
                    return
                }
                print("success true")
                dg.leave()
                self.activityIndicator.stopAnimating()
                self.willRecieveEmails = true
            }
        }
    }
    
    func setButton() {
        if self.willRecieveEmails {
            self.notifsOn()
        }
        else {
            self.notifsOff()
        }
    }
    
    func updateDataBase() {
        let dg = DispatchGroup()
        
        getEmailPreference(dispatchGroup: dg)
        dg.notify(queue: .main) {
            self.setButton()
        }
    }
    
    func notifsOn() {
        self.emailButton.backgroundColor = #colorLiteral(red: 0.762566535, green: 0.3093850772, blue: 0.2170317457, alpha: 1)
        self.emailButton.setTitle("Stop receiving emails", for: .normal)
        self.titleLabel.text = "Email Notifications On"
        self.descriptionLabel.text = "Click below to stop receiving email notifications."
    }
    
    func notifsOff() {
        self.emailButton.backgroundColor = #colorLiteral(red: 0.3260789019, green: 0.5961753091, blue: 0.1608898185, alpha: 1)
        self.emailButton.setTitle("Begin receiving emails", for: .normal)
        self.titleLabel.text = "Email Notifications Off"
        self.descriptionLabel.text = "Click below to begin receiving email notifications."
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
    
    @IBAction func emailButtonClicked(_ sender: Any) {
        updateDataBase()
    }
}
