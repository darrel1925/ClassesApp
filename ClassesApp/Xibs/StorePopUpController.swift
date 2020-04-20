//
//  StorePopUpController.swift
//  ClassesApp
//
//  Created by Darrel Muonekwu on 4/14/20.
//  Copyright © 2020 Darrel Muonekwu. All rights reserved.
//

import UIKit
import Stripe
import FirebaseFunctions
import FirebaseFirestore

class StorePopUpController: UIViewController {
    
    @IBOutlet weak var trackClassesLabel: UILabel!
    @IBOutlet weak var currentCreditsLabel: UILabel!
    @IBOutlet weak var purchasingCreditLabel: UILabel!
    @IBOutlet weak var totalCreditsLabel: UILabel!
    @IBOutlet weak var totalAmountLabel: UILabel!
    @IBOutlet weak var paymentMethodButton: UIButton!
    @IBOutlet weak var confirmPurchaseButton: RoundedButton!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var backgroundView: UIView!
    @IBOutlet weak var containerView: RoundedView!
    
    var paymentContext: STPPaymentContext!
    var applePayPresented = false
    
    var storeController: StoreController!
    var purchasingCredits: Int! // 8624 
    var purchaseAmountInPennies: Int {
        switch purchasingCredits {
        case 1:
            print("Have \(purchasingCredits) credits :)")
            return AppConstants.price_map["1"]!
        case 3:
            print("Have \(purchasingCredits) credits :)")
            return AppConstants.price_map["3"]!
        case 10:
            print("Have \(purchasingCredits) credits :)")
            return AppConstants.price_map["10"]!
        default:
            print("Have \(purchasingCredits) credits :)")
            return -1
        }}
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setUpStripeConfig()
        animateViewDownward()
        setLabels()
        setUpGestures()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        animateViewUpwards()
        setPaymentInfo() // <--- must be here bc purchasingCredits isnt init until view loads
    }
    
    func showApplePay() {
        // Pay
        let merchantId = AppConstants.merchant_id
        let paymentRequest = Stripe.paymentRequest(withMerchantIdentifier: merchantId, country: "US", currency: "USD")
        paymentRequest.paymentSummaryItems = [
            PKPaymentSummaryItem(label: "Rubber duck", amount: 1.5)
        ]
        guard Stripe.canSubmitPaymentRequest(paymentRequest) else {
            assertionFailure()
            return
        }
        guard let authorizationViewController = PKPaymentAuthorizationViewController(paymentRequest: paymentRequest) else {
            assertionFailure()
            return
        }
        authorizationViewController.delegate = self
        self.present(authorizationViewController, animated: true, completion: nil)
    }
    
    func setLabels() {
        if purchasingCredits == 1 {
            trackClassesLabel.text = "Get \(purchasingCredits!) Credit!"
        }
        else {
            trackClassesLabel.text = "Get \(purchasingCredits!) Credits!"
        }
        
        currentCreditsLabel.text = "\(UserService.user.credits)"
        purchasingCreditLabel.text = "\(purchasingCredits!)"
        totalCreditsLabel.text = "\(UserService.user.credits + purchasingCredits)"
        totalAmountLabel.text = purchaseAmountInPennies.penniesToFormattedDollars()
   
    }
    
    func animateViewUpwards() {
        guard let window = UIApplication.shared.keyWindow else { return }
        
        let height: CGFloat = 375
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
        if Stripe.deviceSupportsApplePay() {
            config.additionalPaymentOptions = .applePay
            config.appleMerchantIdentifier = AppConstants.merchant_id
        }
        
        // invokes cloud function to get ephemeral key and customers stripe paymemt info
        let customerContext = STPCustomerContext(keyProvider: StripeAPI)
        paymentContext = STPPaymentContext(customerContext: customerContext, configuration: config, theme: .default())
        paymentContext.paymentAmount = purchaseAmountInPennies
        print("current paymentContext.paymentAmount is \(paymentContext.paymentAmount)")
        paymentContext.delegate = self
        paymentContext.hostViewController = self
        
    }
    func setPaymentInfo() {
        paymentContext.paymentAmount = purchaseAmountInPennies
    }
    
    func presentHomePage() {
        let vc = storyboard?.instantiateViewController(withIdentifier: "HomePageController") as! HomePageController
        let navController = UINavigationController(rootViewController: vc)
        navController.modalPresentationStyle = .fullScreen
        self.present(navController, animated: true, completion: nil)
    }
    
    func presentSuccessAlert() {
        ServerService.updatePurchaseHistory(numCreditsBought: purchasingCredits, totalPrice: purchaseAmountInPennies)
        let message = "Thank you for your support!"
        let alertController = UIAlertController(title: "Success!", message: message, preferredStyle: .alert)
        let okay = UIAlertAction(title: "Okay", style: .default, handler: {(action) in
            self.storeController.setCreditsLabel()
            self.handleDismiss2()
        })
        
        alertController.addAction(okay)
        self.present(alertController, animated: true)
    }
    
    func presentPaymentErrorAlert(error: Error?) {
        removeCredits()
        let message = "There was an error completing you payment. Your card was not charged"
        
        let alertController = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
        let okay = UIAlertAction(title: "Okay", style: .default, handler: nil)
        
        alertController.addAction(okay)
        self.present(alertController, animated: true)
    }
    
    func enablePaymentButton() {
        UIView.animate(withDuration: 0.6) {
            if self.paymentContext.selectedPaymentOption?.label == "Apple Pay" {
                self.confirmPurchaseButton.setTitle("Pay", for: .normal)
                self.confirmPurchaseButton.titleLabel?.font = UIFont(name: "System", size: 47.0)
                self.confirmPurchaseButton.backgroundColor = #colorLiteral(red: 0.1212944761, green: 0.1292245686, blue: 0.141699791, alpha: 1)
            }
            else
            {
                self.confirmPurchaseButton.setTitle("Confirm Purchase", for: .normal)
                self.confirmPurchaseButton.titleLabel?.font = UIFont(name: "Futura", size: 17.0)
                self.confirmPurchaseButton.backgroundColor = #colorLiteral(red: 0.3260789019, green: 0.5961753091, blue: 0.1608898185, alpha: 1)
            }
        }
    }
    
    func disablePaymentButton() {
        UIView.animate(withDuration: 1) {
            self.confirmPurchaseButton.titleLabel?.font = UIFont(name: "Futura", size: 17.0)
            self.confirmPurchaseButton.setTitle("Continue", for: .normal)
            self.confirmPurchaseButton.backgroundColor = #colorLiteral(red: 0.1212944761, green: 0.1292245686, blue: 0.141699791, alpha: 1)
        }
    }
    
    func removeCredits() {
        let db = Firestore.firestore()
        let docRef = db.collection(DataBase.User).document(UserService.user.email)

        let credits = UserService.user.credits
        let newTotalCredits = credits - purchasingCredits

        docRef.setData([DataBase.credits: newTotalCredits], merge: true)
    }
    
    func successfullyAddCredits(dispatchGroup dg: DispatchGroup) -> Bool {
        dg.enter()
        let db = Firestore.firestore()
        let docRef = db.collection(DataBase.User).document(UserService.user.email)

        let credits = UserService.user.credits
        let newTotalCredits = credits + purchasingCredits
        
        var returnValue = true

        docRef.setData([DataBase.credits: newTotalCredits], merge: true) { (error) in
            if let _ = error {
                returnValue = false
                let message = "Unable to add credits. Your car was not charged."
                self.displayError(title: "Error Adding Credits", message: message)
            }
            dg.leave()
        }
        return returnValue
    }
    
    
    func processPayment(paymentContext: STPPaymentContext) {
        let dg = DispatchGroup()
        if !successfullyAddCredits(dispatchGroup: dg) { return }
        
        dg.notify(queue: .main) {
            // process payment
            print("payment amount 1 = \(paymentContext.paymentAmount)")
            paymentContext.theme.translucentNavigationBar = true
            paymentContext.requestPayment()
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
        
        // user confirms credit card purchase
        if confirmPurchaseButton.titleLabel?.text == "Confirm Purchase" {
            self.activityIndicator.startAnimating()
            processPayment(paymentContext: paymentContext)
            return
        }
        
        if confirmPurchaseButton.titleLabel?.text == "Pay" {
            paymentContext.requestPayment()
        }
    }
}


extension StorePopUpController: STPPaymentContextDelegate {
    func paymentContextDidChange(_ paymentContext: STPPaymentContext) {
        print("Did update \(paymentContext.selectedPaymentOption?.label ?? "")")
        print("self.applePayPresented2 = \(self.applePayPresented)")
        
        // If there is a selected payment option
        if  paymentContext.selectedPaymentOption?.label != nil {
            print("found \(paymentContext.selectedPaymentOption?.label ?? "")")
            paymentMethodButton.setTitle(paymentContext.selectedPaymentOption?.label, for: .normal)
            
            let label = paymentContext.selectedPaymentOption?.label
            // If user selected apply pay
            if label == "Apple Pay" {
                // If apple payment screen is currently being shown
                if applePayPresented {
                    processPayment(paymentContext: self.paymentContext)
                    return
                }
                else // If user seleted apple pay for payment (apple payment screen is not being shown)
                {
                    applePayPresented = true
                    self.disablePaymentButton()
                    return
                }
            }
            // User updated payment method to anything thats not apple pay
            applePayPresented = false
            self.disablePaymentButton()
        }
        else // User removed all payment options
        {
            applePayPresented = false
            self.disablePaymentButton()
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
        print("payment amount = \(paymentContext.paymentAmount)")
        print(paymentResult.source.stripeID)
        // unique string to add to payment to ensure no payment request is made twice
        let idempotency = UUID().uuidString.replacingOccurrences(of: "-", with: "")
        let data: [String: Any] = [
            "email": UserService.user.email,
            "total": purchaseAmountInPennies,
            "customer_id": UserService.user.stripeId,
            "idempotency": idempotency,
            "source": paymentResult.source.stripeID
        ]
        
        Functions.functions().httpsCallable("createCharge").call(data) { (result, error) in
            if let error = error {
                print("Error makeing charge: \(error.localizedDescription)")
                self.displayError(title: "Error", message: "Unable to make charge")
                completion(error)
                return
            }
            completion(nil)
        }
    }
    // called whether the payment was successful or not
    func paymentContext(_ paymentContext: STPPaymentContext, didFinishWith status: STPPaymentStatus, error: Error?) {
        activityIndicator.stopAnimating()
        
        switch status {
        case .error:
            presentPaymentErrorAlert(error: error)
            return
        case .success:
            presentSuccessAlert()
            return
        case .userCancellation:
            return
        @unknown default:
            print("ERROR: Unknown error after finishing payment")
            return
        }
    }
}


extension StorePopUpController: PKPaymentAuthorizationViewControllerDelegate  {
    func paymentAuthorizationViewControllerDidFinish(_ controller: PKPaymentAuthorizationViewController) {
        print("paymentAuthorizationViewControllerDidFinish")
        controller.dismiss(animated: true, completion: nil)
    }
    
    func paymentAuthorizationViewController(_ controller: PKPaymentAuthorizationViewController, didAuthorizePayment payment: PKPayment, handler completion: @escaping (PKPaymentAuthorizationResult) -> Void) {
        self.activityIndicator.startAnimating()
        print("payment authorized by user")

        self.activityIndicator.startAnimating()
        processPayment(paymentContext: paymentContext)
        completion(PKPaymentAuthorizationResult(status: .success, errors: nil))
    }
    
    func paymentAuthorizationViewControllerWillAuthorizePayment(_ controller: PKPaymentAuthorizationViewController) {
        print("payment authorized by user2")
        
    }
}
