
//  CheckOutController.swift
//  ClassesApp
//
//  Created by Darrel Muonekwu on 4/3/20.
//  Copyright © 2020 Darrel Muonekwu. All rights reserved.
//

import UIKit
import Stripe
import AudioToolbox
import FirebaseFunctions
import FirebaseFirestore

class CheckOutController: UIViewController {
    
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var paymentMethodButton: UIButton!
    @IBOutlet weak var backgroundView: UIView!
    @IBOutlet weak var currentBalanceLabel: UILabel!
    @IBOutlet weak var newBalanceLabel: UILabel!
    @IBOutlet weak var costLabel: UILabel!
    @IBOutlet weak var repeatCourseLabel: UILabel!
    @IBOutlet weak var containerView: UIView!
    @IBOutlet weak var trackClassesLabel: UILabel!
    @IBOutlet weak var confirmPurchaseButton: RoundedButton!
    @IBOutlet weak var repeatStackView: UIStackView!
    
    var repreatTrackedCourses: Int = 0
    var addClassesVC: AddClassController!
    var courseDict: [String: String]!
        
    override func viewDidLoad() {
        super.viewDidLoad()
        setRepeatTrackedCourses()
        animateViewDownward()
        setLabels()
        setUpGestures()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        animateViewUpwards()
    }
    
    func setRepeatTrackedCourses(){
        for course in Array(courseDict.keys) {
            if UserService.user.trackedClasses.contains(course) {
                repreatTrackedCourses += 1
            }
        }
        
        repeatCourseLabel.text = "+ \(repreatTrackedCourses) credits"
        
        if repreatTrackedCourses == 0 {
            repeatStackView.isHidden = true
        }
    }
    
    func setLabels() {
        let numClasses = StripeCart.cartItems.count
        
        if numClasses == 1 {
            trackClassesLabel.text = "Track \(numClasses) Class!"
        }
        else {
            trackClassesLabel.text = "Track \(numClasses) Classes!"
        }
        
        currentBalanceLabel.text = "\(UserService.user.credits) credits"
        costLabel.text = "\(getTotalCost()) credits"
        let newBalance = UserService.user.credits - getTotalCost()
        newBalanceLabel.text = "\(newBalance) credits"
        
        if newBalance < 0 {
            newBalanceLabel.textColor = #colorLiteral(red: 0.762566535, green: 0.3093850772, blue: 0.2170317457, alpha: 1)
        }
    }
    
    func animateViewUpwards() {
        guard let window = UIApplication.shared.keyWindow else { return }
        
        let height: CGFloat = 275
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
    
    func setUpGestures() {
        backgroundView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(handleDismiss2)))
        
        let swipe: UISwipeGestureRecognizer = UISwipeGestureRecognizer(target: self, action: #selector(handleDismiss2))
        swipe.direction = .down
        backgroundView.addGestureRecognizer(swipe)
    }

    func presentHomePage() {
        let vc = storyboard?.instantiateViewController(withIdentifier: "HomePageController") as! HomePageController
        let navController = UINavigationController(rootViewController: vc)
        navController.modalPresentationStyle = .fullScreen
        self.present(navController, animated: true, completion: nil)
    }
    
    func presentSuccessAlert() {
        ServerService.addToTrackedClasses(classes: Array(courseDict.keys))
        
        AudioServicesPlaySystemSound(1519) // Actuate "Peek" feedback (weak boom)
        let message = "You're all set.\n\nNote: It may take up to 2 minutes to begin tracking your class."

        let alertController = UIAlertController(title: "Success!", message: message, preferredStyle: .alert)
        let okay = UIAlertAction(title: "Okay", style: .default, handler: {(action) in
            self.handleDismiss2()
            self.addClassesVC.navigationController?.popViewController(animated: true)
        })
        
        alertController.addAction(okay)
        self.present(alertController, animated: true)
    }
    
    func presentPaymentErrorAlert() {
        print("error alert presenting")
        let message = "There was an error while attempting to track your classes. Your credits have not been affected."
        
        let alertController = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
        let okay = UIAlertAction(title: "Okay", style: .default, handler: nil)
        
        alertController.addAction(okay)
        self.present(alertController, animated: true)

    }
    
    func getTotalCost() -> Int {
        return StripeCart.cartItems.count - repreatTrackedCourses
    }
    
    func enablePaymentButton() {
        UIView.animate(withDuration: 0.6) {
            self.confirmPurchaseButton.setTitle("Confirm", for: .normal)
            self.confirmPurchaseButton.titleLabel?.font = UIFont(name: "Futura", size: 17.0)
            self.confirmPurchaseButton.backgroundColor = #colorLiteral(red: 0.3260789019, green: 0.5961753091, blue: 0.1608898185, alpha: 1)
        }
    }
    
    func disablePaymentButton() {
        UIView.animate(withDuration: 1) {
            self.confirmPurchaseButton.titleLabel?.font = UIFont(name: "Futura", size: 17.0)
            self.confirmPurchaseButton.setTitle("Continue", for: .normal)
            self.confirmPurchaseButton.backgroundColor = #colorLiteral(red: 0.1212944761, green: 0.1292245686, blue: 0.141699791, alpha: 1)
        }
    }
    
    func addClasses(dispatchGroup dg: DispatchGroup) -> Bool {
        dg.enter()
        print("entering in addClass")
        for code in StripeCart.cartItems {
            if !ServerService.addClassToFirebase(withCode: code, withStatus: courseDict[code] ?? "FULL", viewController: self) {
                ServerService.dispatchGroup.notify(queue: .main) {
                    print("is false")
                    // error occured | remove classes
                    ServerService.removeClassesFromFirebase(withClasses: StripeCart.cartItems)
                    self.activityIndicator.stopAnimating()
                    self.presentPaymentErrorAlert()
                    dg.leave()
                }
            }
        }
        dg.leave()
        return true
    }
    
    func subtractCredits() -> Bool {
        let db = Firestore.firestore()
        let docRef = db.collection(DataBase.User).document(UserService.user.email)
        var returnValue = true
        
        let newBalance = UserService.user.credits - getTotalCost()
        
        
        docRef.setData(["credits": newBalance], merge: true) { (error) in
            if error != nil {
                // error occured | remove classes
                ServerService.removeClassesFromFirebase(withClasses: StripeCart.cartItems)
                self.activityIndicator.stopAnimating()
                self.presentPaymentErrorAlert()
                returnValue = false
            }
        }
        
        activityIndicator.stopAnimating()
        return returnValue
    }
    
    func trackClasses() {
        let dg = DispatchGroup()
        if !addClasses(dispatchGroup: dg) { return }
        
        dg.notify(queue: .main) {
            print("dispatched finished")

            if !self.subtractCredits() { return }
            
            self.presentSuccessAlert()
            
        }
    }
    
    @objc func handleDismiss2() {
        UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 1, options: .curveEaseOut, animations: {
            
            self.backgroundView.alpha = 0
            
        }, completion: {_ in
            UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 1, options: .curveEaseOut, animations: {
                
                self.dismiss(animated: true, completion: nil)
                
            }, completion: nil)
        })
    }
    
    @IBAction func confirmPurchaseClicked(_ sender: Any) {
        
        // if user does not have enough credits
        if UserService.user.credits < getTotalCost() {
            let message = "You do not have enough credits. Go to the Store to get more credits"
            displayError(title: "Not Enough Credits", message: message)
            return
        }

        // if button stil says continue
        if confirmPurchaseButton.titleLabel?.text == "Continue" {
            enablePaymentButton()
            return
        }
        
        // user confirms credit card purchase
        if confirmPurchaseButton.titleLabel?.text == "Confirm" {
            self.activityIndicator.startAnimating()
            trackClasses()
            return
        }
    }
}
