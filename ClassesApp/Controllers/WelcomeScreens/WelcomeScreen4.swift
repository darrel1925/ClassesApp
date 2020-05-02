//
//  WelcomeScreen4.swift
//  ClassesApp
//
//  Created by Darrel Muonekwu on 4/18/20.
//  Copyright © 2020 Darrel Muonekwu. All rights reserved.
//

import UIKit

class WelcomeScreen4: UIViewController {

    @IBOutlet weak var shareButton: RoundedButton!
    @IBOutlet weak var continueButton: RoundedButton!
    @IBOutlet weak var stackView: UIStackView!
    
    var aminateAmount: CGFloat = 350
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setViewDownward()

    }
    
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        setViewDownward()
        animateViewUpwards()
    }
    
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        setViewDownward()
    }
    
    func setViewDownward() {
        shareButton.alpha = 0
        continueButton.alpha = 0
        
        stackView.center.y =  view.frame.maxY + aminateAmount
    }
    
    func animateViewUpwards() {
        guard let window = UIApplication.shared.keyWindow else { return }
            
        UIView.animate(withDuration: 1, delay: 1, usingSpringWithDamping: 1, initialSpringVelocity: 1, options: .curveEaseOut, animations: {
            
            self.shareButton.alpha = 1
            self.stackView.center.y = self.view.frame.maxY - 108
            
        }, completion: { _ in
        
            UIView.animate(withDuration: 1.5, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 1, options: .curveEaseOut, animations: {
                
                self.continueButton.alpha = 1
                
            }, completion: nil )
        })
    }
    
    func presentHomePage() {
        let vc = storyboard?.instantiateViewController(withIdentifier: "HomePageController") as! HomePageController
        let navController = UINavigationController(rootViewController: vc)
        navController.modalPresentationStyle = .fullScreen //or .overFullScreen for transparency
        self.present(navController, animated: true, completion: nil)
    }

    func presentShareController() {
        let shareStr = ReferralLink.message
        let sharingController = UIActivityViewController(activityItems: [shareStr], applicationActivities: nil)
        self.present(sharingController, animated: true, completion: nil)
    }
    
    @IBAction func shareButtonClicked(_ sender: Any) {
        presentShareController()
    }
    
    @IBAction func continueButtonClicked(_ sender: Any) {
        presentHomePage()
    }
}
