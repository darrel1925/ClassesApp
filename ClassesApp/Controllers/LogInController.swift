//
//  LogInController.swift
//  ClassesApp
//
//  Created by Darrel Muonekwu on 3/25/20.
//  Copyright © 2020 Darrel Muonekwu. All rights reserved.
//

import UIKit
import FirebaseAuth

class LogInController: UIViewController {
    
    @IBOutlet weak var emailField: UITextField!
    @IBOutlet weak var passwordField: UITextField!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    let dg = DispatchGroup()
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    func presentHomePage() {
        let vc = storyboard?.instantiateViewController(withIdentifier: "HomePageController") as! HomePageController
        let navController = UINavigationController(rootViewController: vc)
        navController.modalPresentationStyle = .fullScreen //or .overFullScreen for transparency
        self.present(navController, animated: true, completion: nil)
    }
    
    @IBAction func loginClicked(_ sender: Any) {
        activityIndicator.startAnimating()
        let email = emailField.text!
        let password = passwordField.text!
        print("entered")
        Auth.auth().signIn(withEmail: email, password: password) { [weak self] user, error in
            
            if let error = error {
                self?.displayError(error: error)
                debugPrint(error.localizedDescription)
                self?.activityIndicator.stopAnimating()
                return
            }
            
            print("Login was successful")
            self?.activityIndicator.stopAnimating()
            
            
            UserService.dispatchGroup.enter()
            UserService.getCurrentUser(email: email) // <--- calls dispatchGroup.leave()

            UserService.dispatchGroup.notify(queue: .main) {
                self?.presentHomePage()
            }
        }
    }
    
    @IBAction func forgotPasswordClicked(_ sender: Any) {
        let forgotPassVC = ForgotPasswordController()
        forgotPassVC.modalTransitionStyle = .crossDissolve
        forgotPassVC.modalPresentationStyle = .overCurrentContext
        present(forgotPassVC, animated: true, completion: nil)
    }
}
