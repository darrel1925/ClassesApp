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
        emailField.delegate = self
        passwordField.delegate = self
    }
    
    func presentHomePage() {
        let vc = storyboard?.instantiateViewController(withIdentifier: "HomePageController") as! HomePageController
        let navController = UINavigationController(rootViewController: vc)
        navController.modalPresentationStyle = .fullScreen //or .overFullScreen for transparency
        self.present(navController, animated: true, completion: nil)
    }
    
    func credentialsAreValid() -> Bool {
        if !(emailField.text!.isValidSchoolEmail) {
            let message = "Email must be a valid school email address ending in 'edu' Ex. panteatr@uci.edu, bbears@ucla.edu"
            self.displayError(title: "Whoops.", message: message)
            return false
        }
        
        return true
    }
    
    @IBAction func loginClicked(_ sender: Any) {
        if !credentialsAreValid() { return }
        
        activityIndicator.startAnimating()
        let email = emailField.text!
        let password = passwordField.text!
        print("entered")
        Auth.auth().signIn(withEmail: email, password: password) { [weak self] user, error in
            
            if error != nil {
                if let error = AuthErrorCode(rawValue: error!._code) {
                    self?.displayError(title: "Error", message: error.errorMessage)
                    self?.activityIndicator.stopAnimating()
                    return
                }
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

extension LogInController: UITextFieldDelegate {

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField == emailField {
            textField.resignFirstResponder()
            passwordField.becomeFirstResponder()
        } else if textField == passwordField {
            self.view.endEditing(true)
        }
        return true
    }
}
