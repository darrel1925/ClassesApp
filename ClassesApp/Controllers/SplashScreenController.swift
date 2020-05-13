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
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        animation.stopAnimation()
    }
    
    func setScreenName() {
        Stats.setScreenName(screenName: "SplashScreen", screenClass: "SplashScreenController")
    }

}
