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
    @IBOutlet weak var copyButton: RoundedButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationController?.navigationBar.prefersLargeTitles = true
        setLabels()
        setUpGestures()
    }
    
    func setLabels() {
        if UserService.user.numReferrals > 3 {
            toGoLabel.text = "You're all set but why stop there. Click below to share!"
        }
        else {
            toGoLabel.text = "\(3 - UserService.user.numReferrals) to go!"
        }
        
        referralLabel.text = UserService.user.referralLink
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
    
    @objc func handleDismiss() {
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func exitClicked(_ sender: Any) {
        handleDismiss()
    }
    
    @IBAction func copyButtonClicked(_ sender: Any) {
        UIPasteboard.general.string = "\(UserService.user.referralLink)"
        copyButton.setTitle("✓ Copied", for: .normal)
    }
    
    @IBAction func shareButtonClicked(_ sender: Any) {
        presentShareController()
    }
}
