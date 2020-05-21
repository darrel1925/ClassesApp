//
//  StoreController.swift
//  ClassesApp
//
//  Created by Darrel Muonekwu on 4/14/20.
//  Copyright © 2020 Darrel Muonekwu. All rights reserved.
//

import UIKit
import Stripe
import StoreKit
import PassKit
import MessageUI
import AudioToolbox
import FirebaseFunctions
import FirebaseFirestore


class StoreController: UIViewController {
    
    @IBOutlet weak var descriptionLabel: UILabel!
    @IBOutlet weak var shareDescriptionLabel: UILabel!
    @IBOutlet weak var buyButton: RoundedButton!
    @IBOutlet weak var backgroundView: RoundedView!
    @IBOutlet weak var containerView: UIView!
    @IBOutlet weak var redeemButton: UIButton!
    @IBOutlet weak var toGoLabel: UILabel!
    @IBOutlet weak var wantPremiumLabel: UILabel!
    
    // Supported payments
    let paymentNetworks = [PKPaymentNetwork.visa, PKPaymentNetwork.masterCard, PKPaymentNetwork.amex, PKPaymentNetwork.discover]
    // Add in any extra support payments.
    let ApplePayMerchantID = AppConstants.merchant_id
    // Fill in your merchant ID here!
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationController?.navigationBar.prefersLargeTitles = true
        containerView.layer.cornerRadius = 20
        setUpGestures()
        setLabels()
        setRedeemButton()
        setUpStoreKitPayments()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        setLabels()
        setRedeemButton()
    }
    
    func setUpStoreKitPayments() {
        StoreObserver.shared.getProducts() // <- loades in products from apple
        StoreObserver.shared.storeVC = self
    }
    
    func makeStoreKitPayment() {
        StoreObserver.shared.purchasePremium()
    }
    
    func apple_pay() {
        // If user cannot make payments with one of our supported payments
        if !PKPaymentAuthorizationViewController.canMakePayments(usingNetworks: paymentNetworks) {
            print("No apple pay")
//            displayError(title: "Cannot complete purchase", message: "Please contact support.")
            makeStoreKitPayment()
            return
        }
        
        let price: Double = Double(AppConstants.premium_price) / 100.0
        let decimal = NSDecimalNumber(value: price)
        let paymentItem = PKPaymentSummaryItem.init(label: "TrackMy Premium", amount: decimal)
        
        let request = PKPaymentRequest()
        request.currencyCode = "USD"
        request.countryCode = "US"
        request.merchantIdentifier = AppConstants.merchant_id
        request.merchantCapabilities = PKMerchantCapability.capability3DS
        request.supportedNetworks = paymentNetworks
        request.paymentSummaryItems = [paymentItem]
        
        guard let paymentVC = PKPaymentAuthorizationViewController(paymentRequest: request) else {
            displayError(title: "Cannot display payment", message: "Please contact support.")
            return
        }
        paymentVC.delegate = self
        self.present(paymentVC, animated: true, completion: nil)

    }
    
    func setLabels() {
        let price = AppConstants.premium_price.penniesToFormattedDollars()
        buyButton.setTitle(price, for: .normal)
        descriptionLabel.text = "Go premium to track unlimited classes for \(AppConstants.quarter) \(AppConstants.year)."
        
        if UserService.user.hasPremium {
            wantPremiumLabel.text = "Share"
            buyButton.setTitle("You're all set!", for: .normal)
            shareDescriptionLabel.text = "If you're enjoying the app, we would love for you to share. It only takes one click!"
        }
        
        // For referrals
        if UserService.user.numReferrals >= 3 {
            toGoLabel.alpha = 0
        }
        else {
            toGoLabel.text = "\(UserService.user.numReferrals) so far"
        }
        
        if UserService.user.hasPremium {
            shareDescriptionLabel.text =  "If you're enjoying the app, we would love for you to share. It only takes one click!"
        }
    }
    
    func setUpGestures() {
        let swipe1: UISwipeGestureRecognizer = UISwipeGestureRecognizer(target: self, action: #selector(self.handleDismiss))
        swipe1.direction = .down
        navigationController?.navigationBar.addGestureRecognizer(swipe1)
    }
    
    func setRedeemButton() {
        var image: UIImage!

        switch UserService.user.numReferrals {
        case 0:
              image = UIImage(named: "zeroThirds")
          case 1:
              image = UIImage(named: "oneThird")
          case 2:
              image = UIImage(named: "twoThirds")
          case 3:
              image = UIImage(named: "threeThirds")
        default:
            redeemButton.isHidden = true
            return
        }

        redeemButton.setImage(image, for: .normal)
    }
    
    func presentShareController() {
        let shareStr = ReferralLink.message
        let sharingController = UIActivityViewController(activityItems: [shareStr], applicationActivities: nil)
        sharingController.completionWithItemsHandler = {(activityType: UIActivity.ActivityType?, completed: Bool, returnedItems: [Any]?, error: Error?) in
            if let error = error {
                print("error sending referral link", error.localizedDescription)
                return
            }
            else if !completed { // User canceled
                return
            }
            // User completed activity
            Stats.logLinkShared()
        }

        self.present(sharingController, animated: true, completion: nil)
    }
    
    func presentStorePopUpVC() {
        let storePopUpVC = StorePopUpController()
        storePopUpVC.modalPresentationStyle = .overFullScreen
        storePopUpVC.storeController = self
        self.present(storePopUpVC, animated: true, completion: nil)
    }
    
    func presentPremiumAlert() {
        let db = Firestore.firestore()
        let docRef = db.collection(DataBase.User).document(UserService.user.email)
        docRef.updateData([DataBase.has_premium : true])
        let message = "You'll now be able to track unlimited classes for the remainder of the term. Enjoy!"
        displaySimpleError(title: "Welcome To Premium!", message: message, completion: {_ in
            self.handleDismiss()
        })
    }
    
    func presentSupport() {
        guard MFMailComposeViewController.canSendMail() else {
            let message = "Email account not set up on this device. Head over to you device's Setting → Passwords&Accounts → Add Account, then add your email address. You can also send an email to \(AppConstants.support_email)"
            self.displayError(title: "Cannot Send Mail", message: message)
            return
        }
        
        let composer = MFMailComposeViewController()
        composer.mailComposeDelegate = self
        composer.setSubject("Support - Payments")
        composer.setToRecipients([AppConstants.support_email])
        print(AppConstants.support_email)
        present(composer, animated: true)
    }
    
    func presentLearnMore() {
            let vc = self.storyboard?.instantiateViewController(withIdentifier: "FAQController") as! FAQController
            vc.modalPresentationStyle = .overFullScreen
            self.present(vc, animated: true, completion: nil)
        }
    
    func checkForPremium() {
        if UserService.user.hasConfirmedEmail && UserService.user.hasNotPurchased {
            // handle payment
            makeStoreKitPayment()
            return
        }
        else if UserService.user.hasConfirmedEmail && !UserService.user.hasNotPurchased {
            let message = "No worries, you already have premium"
            displayError(title: "Premium Purchased", message: message)
            return
        }
        else if !UserService.user.hasConfirmedEmail && UserService.user.hasNotPurchased {
            displayError(title: "Please cofirm email", message: "You already have premium") { (finished) in
                self.dismiss(animated: true, completion: nil)
            }
            return
        }
        else {
            presentStorePopUpVC()
        }
    }
    
    func updatePremium() {
        let db = Firestore.firestore()
        let docRef = db.collection(DataBase.User).document(UserService.user.email)
        docRef.updateData([DataBase.has_premium: true]) { (err) in
            if let err = err {
                print("Error updating getting premium", err.localizedDescription)
                self.presentPaymentErrorAlert()
                return
            }
            print("Success getting premium")
            self.presentSuccessAlert()
        }
    }

    func presentSuccessAlert() {
        AudioServicesPlaySystemSound(1519) // vibrate phone
        let message = "Thank you for your support!"
        let alertController = UIAlertController(title: "Success!", message: message, preferredStyle: .alert)
        let okay = UIAlertAction(title: "Start Tracking", style: .default, handler: {(action) in
            self.setLabels()
            self.handleDismiss()
            Stats.logPurchase()
        })
        
        alertController.addAction(okay)
        self.present(alertController, animated: true)
    }
    
    func presentPaymentErrorAlert() {
        let message = "There was an error completing you payment. Your card was not charged"
        
        let alertController = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
        let okay = UIAlertAction(title: "Okay", style: .default, handler: nil)
        
        alertController.addAction(okay)
        self.present(alertController, animated: true)
    }
    
    @objc func handleDismiss() {
        dismiss(animated: true, completion: nil )
    }
    
    @IBAction func learnMoreClicked(_ sender: Any) {
        presentLearnMore()
    }
    
    @IBAction func redeemButtonClicked(_ sender: Any) {
        switch UserService.user.numReferrals {
        case 0:
            presentShareController()
        case 1:
            presentShareController()
        case 2:
            presentShareController()
        default:
            if UserService.user.hasPremium { handleDismiss(); return }
            presentPremiumAlert()
        }
    }
    
    @IBAction func buyButtonClicked(_ sender: Any) {
        if UserService.user.hasPremium {
            dismiss(animated: true, completion: nil)
            return
        }
        apple_pay()
//        checkForPremium()
    }
    
    @IBAction func shareClicked(_ sender: Any) {
        presentShareController()
    }
    
    @IBAction func exitButtonClicked(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
}


extension StoreController: MFMailComposeViewControllerDelegate {
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
            controller.displaySimpleError(title: "Error Sending Email", message: "Could not send you email. You can also send an email to \(AppConstants.support_email)", completion: {_ in
                controller.dismiss(animated: true, completion: nil)
            })
            print("failed")
        @unknown default:
            controller.dismiss(animated: true, completion: nil)
            print("unkown")
        }
    }
}

extension StoreController: PKPaymentAuthorizationViewControllerDelegate {
    
    // if authorization finishes, this will dismiss the payment view contoller
        // when its finished
    func paymentAuthorizationViewControllerDidFinish(_ controller: PKPaymentAuthorizationViewController) {
        dismiss(animated: true, completion: nil)
    }
    
    func paymentAuthorizationViewController(_ controller: PKPaymentAuthorizationViewController, didAuthorizePayment payment: PKPayment, handler completion: @escaping (PKPaymentAuthorizationResult) -> Void) {
        print(payment.token.paymentData.base64EncodedString())
        print(payment.token.paymentMethod.displayName)
                
        STPAPIClient.shared().createToken(with: payment) { (token, error) in
            if let _ = error {
                self.displayError(title: "Payment error", message: "There was a problem processing your payment. Please contact support")
                return
            }
            print("got token")
            print("stripe id= \(UserService.user.stripeId)")
            print("payment amount = \(payment.token.paymentMethod.displayName ?? "no payment amt")")
            // unique string to add to payment to ensure no payment request is made twice
            let idempotency = UUID().uuidString.replacingOccurrences(of: "-", with: "")
            let data: [String: Any] = [
                "email": UserService.user.email,
                "total": AppConstants.premium_price,
                "customer_id": UserService.user.stripeId,
                "idempotency": idempotency,
                "source": token?.tokenId
            ]
            
            Functions.functions().httpsCallable("createApplePayCharge").call(data) { (result, error) in
                if let error = error {
                    print("Error makeing charge: \(error.localizedDescription)")
                    self.displayError(title: "Payment Error", message: "Unable to make charge. If this continues please contact support.")
                    let failedResult = PKPaymentAuthorizationResult(status: .failure, errors: [error])
                    
                    completion(failedResult)
                    return
                }
                print("charge successful")
                let successResult = PKPaymentAuthorizationResult(status: .success, errors: nil)
                completion(successResult)
            }
        }
    }
}
