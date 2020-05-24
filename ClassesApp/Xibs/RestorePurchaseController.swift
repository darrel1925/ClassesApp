//
//  RestorePurchaseController.swift
//  ClassesApp
//
//  Created by Darrel Muonekwu on 5/20/20.
//  Copyright © 2020 Darrel Muonekwu. All rights reserved.
//

import UIKit
import StoreKit
import FirebaseFirestore

class RestorePurchaseController: UIViewController {
    
    @IBOutlet weak var restoreButton: RoundedButton!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var containerView: RoundedView!
    @IBOutlet weak var backgroundView: UIView!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
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
        
        let height: CGFloat = containerView.frame.height
        let y = window.frame.height - height
        
        UIView.animate(withDuration: 0.3, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 1, options: .curveEaseOut, animations: {
            
            self.backgroundView.alpha = 0.3
            self.containerView.frame = CGRect(x: 0, y: y, width: window.frame.width, height: height)
            
        }, completion: nil)
    }
    
    func animateViewDownward() {
        backgroundView.alpha = 0
        guard let window = UIApplication.shared.keyWindow else { return }
        containerView.frame = CGRect(x: 0, y: window.frame.height, width: window.frame.width, height: 0)
    }
    
    @objc func handleDismiss() {
        
        UIView.animate(withDuration: 0.25, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 1, options: .curveEaseOut, animations: {
            
            self.backgroundView.alpha = 0
            
        }, completion: {_ in
            UIView.animate(withDuration: 0.25, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 1, options: .curveEaseOut, animations: {
                
                self.dismiss(animated: true, completion: nil)
                
            }, completion: nil)
        })
    }
    
    func updatePremium() {
        let db = Firestore.firestore()
        let docRef = db.collection(DataBase.User).document(UserService.user.email)
        docRef.updateData([DataBase.has_premium: true]) { (err) in
            if let err = err {
                print("Error updating getting premium", err.localizedDescription)
                return
            }
            print("Success getting premium")
        }
    }
    
    @IBAction func RestoreButtonClicked(_ sender: Any) {
        print("restore pressed")
        StoreObserver.shared.didTapMenuType = { didFindPurchase in
            self.activityIndicator.stopAnimating()
            switch didFindPurchase {
            case true:
                self.updatePremium()
            default:
                print("not found")
                self.displaySimpleError(title: "No Purchase Found", message: "We couldn't find a purchase for this quarter.", completion: { (done) in
                    self.handleDismiss()
                })
            }
        }
        
        activityIndicator.startAnimating()
        StoreObserver.shared.getProducts()
        StoreObserver.shared.paymentQueue.restoreCompletedTransactions()
    }
}
