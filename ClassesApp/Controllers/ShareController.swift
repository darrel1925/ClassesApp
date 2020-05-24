//
//  ShareController.swift
//  ClassesApp
//
//  Created by Darrel Muonekwu on 4/28/20.
//  Copyright © 2020 Darrel Muonekwu. All rights reserved.
//

import UIKit

class ShareController: UIViewController {
    
    @IBOutlet weak var toGoLabel: UILabel!
    @IBOutlet weak var referralLabel: UILabel!
    @IBOutlet weak var descriptionLabel: UILabel!
    @IBOutlet weak var copyButton: RoundedButton!
    @IBOutlet weak var redeemButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationController?.navigationBar.prefersLargeTitles = true
        setLabels()
        setRedeemButton()
        setUpGestures()
        setScreenName()
    }
    
    func setScreenName() {
        Stats.setScreenName(screenName: "ShareController", screenClass: "ShareController")
    }
    
    func setLabels() {
        
        if UserService.user.numReferrals >= 3 {
            toGoLabel.text = "You're all set!"
        }
        else {
            if UserService.user.numReferrals == 1 {
                toGoLabel.text = "\(UserService.user.numReferrals) referral, so far!"
            }
            else {
                toGoLabel.text = "\(UserService.user.numReferrals) referrals, so far!"
            }
        }
        
        if UserService.user.hasPremium || UserService.user.authenticated {
            descriptionLabel.text =  "If you're enjoying the app, we would love for you to share. It only takes one click!"
        } else {
            descriptionLabel.text =  "Get free premium for Fall 2020 when 3 people download the app from your link and track their first class!"
        }
        
        
        toGoLabel.isHidden = UserService.user.authenticated
        referralLabel.text = UserService.user.referralLink
        toGoLabel.isHidden = UserService.user.authenticated
        redeemButton.isHidden = UserService.user.authenticated
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
        default:
            image = UIImage(named: "threeThirds")
        }
        redeemButton.frame.size = CGSize(width: view.frame.height * 0.2, height: view.frame.height * 0.2)
        redeemButton.setImage(image, for: .normal)
    }
    
    func presentShareController() {
        print("entered")
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
    
    func presentPremiumAlert() {
        let message = "You'll now be able to track unlimited classes for the remainder of the term. Enjoy!"
        displaySimpleError(title: "Welcome To Premium!", message: message, completion: {_ in
            self.handleDismiss()
        })
    }
    
    @IBAction func redeemButonClicked(_ sender: Any) {
        switch UserService.user.numReferrals {
        case 0:
            presentShareController()
        case 1:
            presentShareController()
        case 2:
            presentShareController()
        default:
            if UserService.user.hasPremium { self.handleDismiss(); return }
            presentPremiumAlert()
        }
    }
    
    @objc func handleDismiss() {
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func exitClicked(_ sender: Any) {
        handleDismiss()
    }
    
    @IBAction func copyButtonClicked(_ sender: Any) {
        UIPasteboard.general.string = "\(UserService.user.referralLink)"
        copyButton.setTitle("✓ Copied", for: .normal)
        Stats.logCopiedLinkToClip()
    }
    
    @IBAction func shareButtonClicked(_ sender: Any) {
        presentShareController()
    }
}


