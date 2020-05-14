//
//  LogInController.swift
//  ClassesApp
//
//  Created by Darrel Muonekwu on 3/25/20.
//  Copyright © 2020 Darrel Muonekwu. All rights reserved.
//

import UIKit
import FirebaseAuth
import FirebaseFirestore

class LogInController: UIViewController {
    
    @IBOutlet weak var emailField: UITextField!
    @IBOutlet weak var passwordField: UITextField!
    @IBOutlet weak var eyeButton: UIButton!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    let dg = DispatchGroup()
    var securityTextVisible = false

    override func viewDidLoad() {
        super.viewDidLoad()
        emailField.delegate = self
        passwordField.delegate = self
        setScreenName()
    }
    
    func setScreenName() {
        Stats.setScreenName(screenName: "LogIn", screenClass: "LogInController")
    }
    
    func presentEmailSupport() {
        let vc = self.storyboard?.instantiateViewController(withIdentifier: "EmailSupportController") as! EmailSupportController
        let navController = UINavigationController(rootViewController: vc)
        navController.modalPresentationStyle = .fullScreen
        self.present(navController, animated: true, completion: nil)
    }
    
    func presentHomePage() {
        let vc = storyboard?.instantiateViewController(withIdentifier: "HomePageController") as! HomePageController
        let navController = UINavigationController(rootViewController: vc)
        navController.modalPresentationStyle = .fullScreen
        self.present(navController, animated: true, completion: nil)
    }
    
    func presentWelcomeScreen() {
        let vc = storyboard?.instantiateViewController(withIdentifier: "PageController") as! PageController
        vc.modalPresentationStyle = .fullScreen
        self.present(vc, animated: true, completion: nil)
    }
    
    func presentEmailVerificationAlert(user: FirebaseAuth.User) {
        let message = "A verification email has been send to \(user.email!). Please verifiy your account or click Resend to receive a new verification email."
        let alert = UIAlertController(title: "Email Not Verified", message: message, preferredStyle: .alert)
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .default, handler: nil)
        let resendAction = UIAlertAction(title: "Resend", style: .default, handler: {_ in
            user.sendEmailVerification { (err) in
                if let err = err {
                    print("error verifying email", err.localizedDescription)
                    return
                }
                print("Resent email verification")
            }
        })
        
        alert.addAction(cancelAction)
        alert.addAction(resendAction)
        present(alert, animated: true, completion: nil)
    }
    
    func presentNextPage(user: FirebaseAuth.User) {
        
        // If user has not seen welcome page
        if !UserService.user.seenWelcomePage {
            let db = Firestore.firestore()
            let docRef = db.collection(DataBase.User).document(UserService.user.email)
            docRef.updateData([DataBase.seen_welcome_page: true])
            presentWelcomeScreen()
            return
        }
        
        presentHomePage()
    }
    
    func credentialsAreValid() -> Bool {
        if !(emailField.text!.isValidSchoolEmail) {
            let message = "Email must be a valid school email address ending in 'edu' \n\nEx. panteatr@uci.edu, bbears@ucla.edu"
            self.displayError(title: "Whoops.", message: message)
            return false
        }
        return true
    }
    
    func handleReferral() {
        // this device was referred
        if UserDefaults.standard.bool(forKey: Defaults.wasReferred) {
            // if referral was used alraedy, return
            if UserDefaults.standard.bool(forKey: Defaults.hasUsedOneReferral) { print("referral used");return }
            // This device will not be able to send anyone else a referral link
            UserDefaults.standard.set(true, forKey: Defaults.hasUsedOneReferral)
            print("This device will not be able to send anyone a referral link.")
        }
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
            
            user?.user.reload(completion: { (err) in // reloads user fields, like emailVerified:
                if let _ = err{ print("unable to reload user") ; return}
                print("user reloaded")
            })
            
            print("Login was successful")
            self?.activityIndicator.stopAnimating()
            
            UserService.dispatchGroup.enter()
            UserService.getCurrentUser(email: email) // <--- calls dispatchGroup.leave()
            
            UserService.dispatchGroup.notify(queue: .main) {
                self?.handleReferral()
                self?.presentNextPage(user: user!.user)
            }
        }
    }
    
    @IBAction func forgotPasswordClicked(_ sender: Any) {
        let forgotPassVC = ForgotPasswordController()
        forgotPassVC.modalTransitionStyle = .crossDissolve
        forgotPassVC.modalPresentationStyle = .overCurrentContext
        present(forgotPassVC, animated: true, completion: nil)
    }
    
    @IBAction func contactSupportClicked(_ sender: Any) {
        presentEmailSupport()
    }
    
    @IBAction func eyeButtonClicked(_ sender: Any) {
        // make text secured
        if securityTextVisible {
            securityTextVisible = false
            passwordField.isSecureTextEntry = false
            passwordField.keyboardType = .asciiCapable
            let image = UIImage(named:"openedEye")!
            eyeButton.setImage(image, for: .normal)
        }
        
        // make text visible
        else {
            securityTextVisible = true
            passwordField.isSecureTextEntry = true
            let image = UIImage(named:"closedEye")!
            eyeButton.setImage(image, for: .normal)
        }
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
