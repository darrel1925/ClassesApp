
//  CheckOutController.swift
//  ClassesApp
//
//  Created by Darrel Muonekwu on 4/3/20.
//  Copyright © 2020 Darrel Muonekwu. All rights reserved.
//

import UIKit
import Stripe
import FirebaseFunctions
import FirebaseFirestore

class CheckOutController: UIViewController {
    
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var paymentMethodButton: UIButton!
    @IBOutlet weak var backgroundView: UIView!
    @IBOutlet weak var totalLabel: UILabel!
    @IBOutlet weak var containerView: UIView!
    @IBOutlet weak var trackClassesLabel: UILabel!
    @IBOutlet weak var confirmPurchaseButton: RoundedButton!
    
    var paymentContext: STPPaymentContext!
    var addClassesVC: AddClassController!
    var courseDict: [String: String]!
    var applePayPresented = false
    
    let applePayButton: PKPaymentButton = PKPaymentButton(paymentButtonType: .plain, paymentButtonStyle: .black)

    
    override func viewDidLoad() {
        super.viewDidLoad()
        applePayButton.isEnabled = Stripe.deviceSupportsApplePay()
        
        
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
    
    func showApplePay() {
        // Pay
        let merchantId = "merchant.com.darrelmuonekwu.ClassesApp"
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
        if Stripe.deviceSupportsApplePay() {
            config.additionalPaymentOptions = .applePay
            config.appleMerchantIdentifier = "merchant.com.darrelmuonekwu.ClassesApp"
        }
            
        // invokes cloud function to get ephemeral key and customers stripe paymemt info
        let customerContext = STPCustomerContext(keyProvider: StripeAPI)
        paymentContext = STPPaymentContext(customerContext: customerContext, configuration: config, theme: .default())
        paymentContext.paymentAmount = StripeCart.total
        paymentContext.delegate = self
        paymentContext.hostViewController = self
        
    }
    
    func setPaymentInfo() {
        print("\(StripeCart.cartItems)")
        totalLabel.text = StripeCart.total.penniesToFormattedDollars()
        paymentContext.paymentAmount = StripeCart.total // <-- reset amount being charged
    }

    func presentHomePage() {
        let vc = storyboard?.instantiateViewController(withIdentifier: "HomePageController") as! HomePageController
        let navController = UINavigationController(rootViewController: vc)
        navController.modalPresentationStyle = .fullScreen
        self.present(navController, animated: true, completion: nil)
    }
    
    func presentSuccessAlert() {
        ServerService.updatePurchaseHistory(withClasses: StripeCart.cartItems)

        let db = Firestore.firestore()
        let docRef = db.collection("User").document(UserService.user.email)
        
        var free_classes = UserService.user.freeClasses - StripeCart.cartItems.count
        if free_classes < 0 {
            free_classes = 0
        }
            
        docRef.setData(["free_classes": free_classes], merge: true)

        let message = "Thank you for your purchase.\nNote: It may take up to 2 minutes to begin tracking your class."

        let alertController = UIAlertController(title: "Success!", message: message, preferredStyle: .alert)
        let okay = UIAlertAction(title: "Okay", style: .default, handler: {(action) in
            self.handleDismiss2()
            self.addClassesVC.navigationController?.popViewController(animated: true)
        })
        
        alertController.addAction(okay)
        self.present(alertController, animated: true)
    }
    
    func presentPaymentErrorAlert(error: Error?) {
        ServerService.removeClassesFromFirebase(withClasses: StripeCart.cartItems)
        let message = "There was an error completing you payment. Your card was not charged"
//        let message = error?.localizedDescription ?? "unable to get error message in cart"
        
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
    
    func successfullyAddedClasses(dispatchGroup dg: DispatchGroup) -> Bool {
        dg.enter()
        for code in StripeCart.cartItems {
            if !ServerService.addClassToFirebase(withCode: code, withStatus: courseDict[code] ?? "FULL", viewController: self) {
                // error occured | remove classes
                ServerService.removeClassesFromFirebase(withClasses: StripeCart.cartItems)
                dg.leave()
                return false
            }
        }
        dg.leave()
        return true
    }
    
    
    func processPayment(paymentContext: STPPaymentContext) {
        let dg = DispatchGroup()
        if !successfullyAddedClasses(dispatchGroup: dg) { return }
        
        dg.notify(queue: .main) {
            // process payment
            
            if paymentContext.paymentAmount > 0 {
                paymentContext.theme.translucentNavigationBar = true
                paymentContext.requestPayment()
            }
            else
            {
                self.presentSuccessAlert()
                self.activityIndicator.stopAnimating()
            }
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

extension CheckOutController: STPPaymentContextDelegate {
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
        
        print("payment amy is \(paymentResult.description)")
        print("stripe id= \(UserService.user.stripeId)")
        print(paymentResult.source.stripeID)
        // unique string to add to payment to ensure no payment request is made twice
        let idempotency = UUID().uuidString.replacingOccurrences(of: "-", with: "")
        let data: [String: Any] = [
            "email": UserService.user.email,
            "total": StripeCart.total,
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


extension CheckOutController: PKPaymentAuthorizationViewControllerDelegate  {
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
