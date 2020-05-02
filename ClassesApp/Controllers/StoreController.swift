//
//  StoreController.swift
//  ClassesApp
//
//  Created by Darrel Muonekwu on 4/14/20.
//  Copyright © 2020 Darrel Muonekwu. All rights reserved.
//

import UIKit
import Stripe
import FirebaseFunctions
import FirebaseFirestore


class StoreController: UIViewController {
    
    @IBOutlet weak var descriptionLabel: UILabel!
    @IBOutlet weak var shareDescription: UILabel!
    @IBOutlet weak var buyButton: RoundedButton!
    @IBOutlet weak var backgroundView: RoundedView!
    @IBOutlet weak var containerView: UIView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationController?.navigationBar.prefersLargeTitles = true
        containerView.layer.cornerRadius = 20
        setUpGestures()
        setLabels()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        setLabels()
    }

    func setLabels() {
        descriptionLabel.text = "Go premium to track unlimited classes for \(AppConstants.quarter) \(AppConstants.year)."
        
        if UserService.user.hasPremium {
            buyButton.setTitle("You're all set!", for: .normal)
            shareDescription.text = "If you're enjoying the app, we would love for you to share. It only takes one click!"
        }
    }
    
    func setUpGestures() {
        let swipe1: UISwipeGestureRecognizer = UISwipeGestureRecognizer(target: self, action: #selector(self.handleDismiss))
        swipe1.direction = .down
        navigationController?.navigationBar.addGestureRecognizer(swipe1)
    }
    
    func presentShareController() {
        let shareStr = ReferralLink.message
        let sharingController = UIActivityViewController(activityItems: [shareStr], applicationActivities: nil)
        self.present(sharingController, animated: true, completion: nil)
    }
    
    func presentStorePopUpVC() {
        let storePopUpVC = StorePopUpController()
        storePopUpVC.modalPresentationStyle = .overFullScreen
        storePopUpVC.storeController = self
        self.present(storePopUpVC, animated: true, completion: nil)
    }
    
    @objc func handleDismiss() {
        dismiss(animated: true, completion: nil )
    }
    
    @IBAction func buyButtonClicked(_ sender: Any) {
        if UserService.user.hasPremium { return }
        presentStorePopUpVC()
    }
    
    @IBAction func shareClicked(_ sender: Any) {
        presentShareController()
    }
    
    @IBAction func exitButtonClicked(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
}

