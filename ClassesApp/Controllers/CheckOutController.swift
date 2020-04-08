
//  CheckOutController.swift
//  ClassesApp
//
//  Created by Darrel Muonekwu on 4/3/20.
//  Copyright © 2020 Darrel Muonekwu. All rights reserved.
//

import UIKit
import Stripe
import FirebaseFunctions

class CheckOutController: UIViewController {
    
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var paymentMethodButton: UIButton!
    @IBOutlet weak var backgroundView: UIView!
    @IBOutlet weak var totalLabel: UILabel!
    @IBOutlet weak var containerView: UIView!
    @IBOutlet weak var trackClassesLabel: UILabel!
    @IBOutlet weak var confirmPurchaseButton: RoundedButton!
    
    var paymentContext: STPPaymentContext!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setUpStripeConfig()
        animateViewDownward()
        setTrackClassesLabel()
        setPaymentInfo()
        setUpGestures()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        animateViewUpwards()
    }
    
    func setTrackClassesLabel() {
        let numClasses = StripeCart.cartItems.count
        
        if numClasses == 1 {
            trackClassesLabel.text = "Track \(numClasses) Class!"
        }
        else {
            trackClassesLabel.text = "Track \(numClasses) Classes!"
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
    
    func setUpStripeConfig() {
        let config = STPPaymentConfiguration.shared()
        config.createCardSources = true // user card info is save after user enters it in
        config.requiredBillingAddressFields = .none
        config.requiredShippingAddressFields = .none
        
        
        // invokes cloud function to get ephemeral key and customers stripe paymemt info
        let customerContext = STPCustomerContext(keyProvider: StripeAPI)
        paymentContext = STPPaymentContext(customerContext: customerContext, configuration: config, theme: .default())
        paymentContext.paymentAmount = StripeCart.total
        paymentContext.delegate = self
        paymentContext.hostViewController = self
    }
    
    func presentSuccessAlert(title: String, message: String) {
        
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let okay = UIAlertAction(title: "Okay", style: .default, handler: {(action) in
            //            self.performSegue(withIdentifier: Segues.toMapController, sender: nil)
            // TODO: GO TO HOMEPAGE AGAIN?
        })
        
        alertController.addAction(okay)
        self.present(alertController, animated: true)
    }
    
    func setPaymentInfo() {
        print("\(StripeCart.cartItems)")
        totalLabel.text = StripeCart.total.penniesToFormattedDollars()
        paymentContext.paymentAmount = StripeCart.total // <-- reset amount being charged
        
    }
    
    func enablePaymentButton() {
        UIView.animate(withDuration: 1) {
            self.confirmPurchaseButton.setTitle("Confirm Purchase", for: .normal)
            self.confirmPurchaseButton.backgroundColor = #colorLiteral(red: 0.3260789019, green: 0.5961753091, blue: 0.1608898185, alpha: 1)
            //               self.confirmPurchaseButton.setTitleColor(#colorLiteral(red: 0.1212944761, green: 0.1292245686, blue: 0.141699791, alpha: 1), for: .normal)
        }
    }
    
    func disablePaymentButton() {
        UIView.animate(withDuration: 1) {
            self.confirmPurchaseButton.setTitle("Continue", for: .normal)
            self.confirmPurchaseButton.backgroundColor = #colorLiteral(red: 0.1212944761, green: 0.1292245686, blue: 0.141699791, alpha: 1)
            //               self.confirmPurchaseButton.setTitleColor(#colorLiteral(red: 0.1212944761, green: 0.1292245686, blue: 0.141699791, alpha: 1), for: .normal)
        }
    }
    
    @objc func handleDismiss2() {
        print("tapped3")
        
        UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 1, options: .curveEaseOut, animations: {
            
            self.backgroundView.alpha = 0
            
        }, completion: {_ in
            UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 1, options: .curveEaseOut, animations: {
                
                self.dismiss(animated: true, completion: nil)
                
            }, completion: nil)
        })
    }
    
    @IBAction func paymentMethodClicked(_ sender: Any) {
        paymentContext.theme.translucentNavigationBar = true
        paymentContext.presentPaymentOptionsViewController()
    }
    
    @IBAction func confirmPurchaseClicked(_ sender: Any) {
        // if no payment method is selected
        if paymentContext.selectedPaymentOption == nil {
            paymentContext.theme.translucentNavigationBar = true
            paymentContext.presentPaymentOptionsViewController()
            return
        }
        
        // if button stil says continue
        if confirmPurchaseButton.titleLabel?.text == "Continue" {
            enablePaymentButton()
            return
        }
        
        // process payment
        activityIndicator.startAnimating()
        paymentContext.theme.translucentNavigationBar = true
        paymentContext.requestPayment()
    }
}

extension CheckOutController: STPPaymentContextDelegate {
    func paymentContextDidChange(_ paymentContext: STPPaymentContext) {
        print("Did update \(paymentContext.selectedPaymentOption?.label)")
        self.disablePaymentButton()
        
        // Update selected payment method
        if  paymentContext.selectedPaymentOption?.label != nil {
            print("found \(paymentContext.selectedPaymentOption?.label)")
            paymentMethodButton.setTitle(paymentContext.selectedPaymentOption?.label, for: .normal)
        }
        else
        {
            paymentMethodButton.setTitle("Select Method", for: .normal)
        }
    }
    
    // called if there was an error getting payment info from customer
    func paymentContext(_ paymentContext: STPPaymentContext, didFailToLoadWithError error: Error) {
        activityIndicator.stopAnimating()
        
        let alertContoller = UIAlertController(title: "Error", message: error.localizedDescription, preferredStyle: .alert)
        
        let retry = UIAlertAction(title: "Retry", style: .default, handler: {(action) in
            self.paymentContext.retryLoading()
        })
        let cancel = UIAlertAction(title: "Cancel", style: .cancel, handler: {(action) in
            self.dismiss(animated: true, completion: nil)
        })
        
        alertContoller.addAction(cancel)
        alertContoller.addAction(retry)
        present(alertContoller, animated: true, completion: nil)
        
    }
    
    // did begin a stripe payment
    func paymentContext(_ paymentContext: STPPaymentContext, didCreatePaymentResult paymentResult: STPPaymentResult, completion: @escaping STPErrorBlock) {
        
        print("stripe id= \(UserService.user.stripeId)")
        // unique string to add to payment to ensure no payment request is made twice
        let idempotency = UUID().uuidString.replacingOccurrences(of: "-", with: "")
        let data: [String: Any] = [
            "email": UserService.user.email,
            "total": StripeCart.total,
            "customer_id": UserService.user.stripeId,
            "idempotency": idempotency
        ]
        
        Functions.functions().httpsCallable("createCharge").call(data) { (result, error) in
            if let error = error {
                print("Error makeing charge: \(error.localizedDescription)")
                self.displayError(title: "Error", message: "Unable to make charge")
                completion(error)
                return
            }
            
            StripeCart.clearCart()
            completion(nil)
        }
    }
    // called whether the payment was successful or not
    func paymentContext(_ paymentContext: STPPaymentContext, didFinishWith status: STPPaymentStatus, error: Error?) {
        let title: String
        let message: String
        activityIndicator.stopAnimating()
        
        switch status {
        case .error:
            title = "Error"
            message = error?.localizedDescription ?? "unable to get error message in cart"
            print("was error")
            break
        case .success:
            title = "Success!"
            message = "Thank you for your purchase."
            print("was successful")
            break
        case .userCancellation:
            print("user cancel")
            return
        @unknown default:
            print("ERROR: Unknown error after finishing payment")
            return
        }
        
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let okay = UIAlertAction(title: "Okay", style: .default, handler: {(action) in
            self.dismiss(animated: true, completion: nil)
        })
        
        alertController.addAction(okay)
        self.present(alertController, animated: true)
        
    }
}


