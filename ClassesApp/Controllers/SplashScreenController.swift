//
//  SplashScreenController.swift
//  ClassesApp
//
//  Created by Darrel Muonekwu on 3/25/20.
//  Copyright © 2020 Darrel Muonekwu. All rights reserved.
//

import UIKit
import Firebase

class SplashScreenController: UIViewController {
    
    @IBOutlet weak var backgroundImageView: UIImageView!
    
    var animation: AnimateStartPage!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        animation = AnimateStartPage(startVC: self)
        setScreenName()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        animation.beginAnimation()
        checkWelcomeScreen()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        animation.stopAnimation()
    }
    
    func setScreenName() {
        Stats.setScreenName(screenName: "SplashScreen", screenClass: "SplashScreenController")
    }
    
    func presentWelcomeScreen() {
        let vc = storyboard?.instantiateViewController(withIdentifier: "PageController") as! PageController
        vc.modalPresentationStyle = .fullScreen
        self.present(vc, animated: true, completion: nil)
    }
    
    func checkWelcomeScreen() {
        // Has not seen welcome screen
        print("welson", UserDefaults.standard.bool(forKey: Defaults.hasSeenWelcomeScreen))
        if !UserDefaults.standard.bool(forKey: Defaults.hasSeenWelcomeScreen) {
            UserDefaults.standard.set(true, forKey: Defaults.hasSeenWelcomeScreen)
            presentWelcomeScreen()
        }
    }
    
}
