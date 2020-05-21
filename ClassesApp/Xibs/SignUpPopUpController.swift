//
//  SignUpPopUpController.swift
//  ClassesApp
//
//  Created by Darrel Muonekwu on 5/14/20.
//  Copyright © 2020 Darrel Muonekwu. All rights reserved.
//

import UIKit
import FirebaseAuth
import FirebaseFirestore
import FirebaseFunctions

class SignUpPopUpController: UIViewController {
    
    @IBOutlet weak var backgroundView: UIView!
    @IBOutlet weak var containerView: RoundedView!
    
    @IBOutlet weak var emailField: UITextField!
    @IBOutlet weak var passwordField: UITextField!
    @IBOutlet weak var confirmPasswordField: UITextField!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var passwordEyeButton: UIButton!
    @IBOutlet weak var confirmEyeButton: UIButton!
    
    let db = Firestore.firestore()
    var addToListVC: AddToListController!
    
    let schoolExtDict: [String: String] = [
        "UCI": "uci",
        "UCLA": "ucla",
        "SJSU": "sjsu"
    ]
    var securityTextVisible = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setUpGestures()
        animateViewDownward()
        
        setDelegates()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        animateViewUpwards()
    }    
    
    func setUpGestures() {
        backgroundView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(handleDismiss)))
        
        let swipe: UISwipeGestureRecognizer = UISwipeGestureRecognizer(target: self, action: #selector(handleDismiss))
        swipe.direction = .down
        backgroundView.addGestureRecognizer(swipe)
    }
    
    func animateViewUpwards() {
        guard let window = UIApplication.shared.keyWindow else { return }
        
        let height: CGFloat = 430
        let y = window.frame.height - height
        
        UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 1, options: .curveEaseOut, animations: {
            
            self.backgroundView.alpha = 0.5
            self.containerView.frame = CGRect(x: 0, y: y, width: window.frame.width, height: height)
            
        }, completion: nil)
    }
    
    func animateViewDownward() {
        backgroundView.alpha = 0
        guard let window = UIApplication.shared.keyWindow else { return }
        containerView.frame = CGRect(x: 0, y: window.frame.height, width: window.frame.width, height: 0)
    }
    
    
    func setDelegates() {
        emailField.delegate = self
        passwordField.delegate = self
        confirmPasswordField.delegate = self
    }
    
    func presentTermsController() {
        let vc = storyboard?.instantiateViewController(withIdentifier: "TermsController") as! TermsController
        let navController = UINavigationController(rootViewController: vc)
        navController.modalPresentationStyle = .fullScreen
        self.present(navController, animated: true, completion: nil)
    }
    
    func presentPrivacyController() {
        let vc = storyboard?.instantiateViewController(withIdentifier: "PrivacyController") as! PrivacyController
        let navController = UINavigationController(rootViewController: vc)
        navController.modalPresentationStyle = .fullScreen
        self.present(navController, animated: true, completion: nil)
    }
    
    func presentVerificationSentAlert() {
        let message = "Verify your email to track your next class!"
        let alert = UIAlertController(title: "Verification Email Sent", message: message, preferredStyle: .alert)
        
        let okayAction = UIAlertAction(title: "Okay", style: .default, handler: {_ in
            self.handleSignUpSuccess()
        })
        
        alert.addAction(okayAction)
        present(alert, animated: true, completion: nil)
    }
    
    func presentHomePage() {
        let vc = storyboard?.instantiateViewController(withIdentifier: "HomePageController") as! HomePageController
        let navController = UINavigationController(rootViewController: vc)
        navController.modalPresentationStyle = .fullScreen
        self.present(navController, animated: true, completion: nil)
    }
    
    func sendVerificationEmail(user: FirebaseAuth.User) {
        user.sendEmailVerification { (error) in
            if let error = error {
                print("Error sending verification email", error.localizedDescription)
            }
        }
    }
    
    func credentialsAreValid() -> Bool {
        if !(emailField.text!.isValidSchoolEmail) {
            let message = "Email must be a valid school email address ending in 'edu' /n/n Ex. panteatr@uci.edu, bbears@ucla.edu"
            self.displayError(title: "Invalid School Email.", message: message)
            return false
        }
        else if (passwordField.text!.count < 6 || passwordField.text!.containsWhitespace) {
            print(passwordField.text!.count < 6)
            print(passwordField.text!.containsWhitespace)
            let message = "Password must be at least 6 charaters and contain no spaces."
            self.displayError(title: "Weak Password.", message: message)
            return false
        }
        else if !(passwordField.text! == confirmPasswordField.text) {
            let message = "Looks like your passwords don't match. Let's give it another shot."
            self.displayError(title: "Passwords don't match.", message: message)
            return false
        }
        let email = emailField.text!
        let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
        let emailArray = trimmedEmail.components(separatedBy: "@") // ['pname', 'uci.edu']
        let extensionArray = emailArray[1].components(separatedBy: ".") // ['uci', 'edu']
        let schoolExtenstion = extensionArray[0]
        
        // Chose .ucsf is not in the schoolExtDict values
        if !Array(schoolExtDict.values).contains(schoolExtenstion) {
            let message = "Email must be a valid school email address ending in '.edu' /n/n Ex. panteatr@uci.edu, bbears@ucla.edu"
            self.displayError(title: "School Email Required.", message: message)
            return false
        }
        return true
    }
    
    func createFireStoreUser(user: User, fireUser: FirebaseAuth.User) {
        // Add a new document with a generated ID
        let ref = db.collection(DataBase.User).document(user.email)
        let user_dict = User.modelToData(user: user)
        getStripeId(data: user_dict)
        
        ref.setData(user_dict, merge: true) { err in
            if let err = err {
                print("Error adding document: \(err)")
                self.displayError(error: err)
                self.activityIndicator.stopAnimating()
                return
            }
            self.activityIndicator.stopAnimating()
            
            UserService.dispatchGroup.enter()
            UserService.getCurrentUser(email: user.email) // <--- calls dispatchGroup.leave()
            
            UserService.dispatchGroup.notify(queue: .main) {
                self.presentVerificationSentAlert()
                UserService.generateReferralLink()
                Stats.logSignUp()
                Stats.setUserProperty(school: UserService.user.school)
            }
        }
    }
    
    func getStripeId(data: [String: Any]) {
        
        Functions.functions().httpsCallable("createStripeCustomer").call(data) { (result, error) in
            print("got a responce")
            
            if let error = error {
                print("Could Not Create Stripe ID: \(error.localizedDescription)")
                return
            }
            
            guard let key = result?.data as? [String: Any] else {
                print("could not get result")
                return
            }
            
            print("Stripe customer created successfully")
            print(key)
        }
    }
    
    @objc func handleDismiss() {
        
        UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 1, options: .curveEaseOut, animations: {
            
            self.view.alpha = 0
            
        }, completion: {_ in
            UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 1, options: .curveEaseOut, animations: {
                
                self.dismiss(animated: true, completion: nil)
                
            }, completion: nil)
        })
    }
    
    func handleSignUpSuccess() {
        UIView.animate(withDuration: 0.25, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 1, options: .curveEaseOut, animations: {
            
            self.backgroundView.alpha = 0
            
        }, completion: {_ in
            UIView.animate(withDuration: 0.25, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 1, options: .curveEaseOut, animations: {
                
                // if we are coming from add to list controller
                if self.addToListVC != nil {
                    self.dismiss(animated: true, completion: { self.addToListVC.trackClasses() })
                }
                
            }, completion: nil)
        })
    }
    
    @objc func dismissKeyboard() {
        view.endEditing(true)
    }
    
    @IBAction func exitButtonClicked(_ sender: Any) {
        handleDismiss()
    }
    
    @IBAction func termsButtonClicked(_ sender: Any) {
        presentTermsController()
    }
    
    @IBAction func privacybuttonClicked(_ sender: Any) {
        presentPrivacyController()
    }
    
    @IBAction func haveAccountClicked(_ sender: Any) {
    }
    
    @IBAction func eyeClicked(_ sender: Any) {
        // make text secured
        if securityTextVisible {
            securityTextVisible = false
            passwordField.isSecureTextEntry = false
            confirmPasswordField.isSecureTextEntry = false
            passwordField.keyboardType = .asciiCapable
            confirmPasswordField.keyboardType = .asciiCapable
            let image = UIImage(named:"openedEye")!
            passwordEyeButton.setImage(image, for: .normal)
            confirmEyeButton.setImage(image, for: .normal)
        }
            // make text visible
        else {
            securityTextVisible = true
            passwordField.isSecureTextEntry = true
            confirmPasswordField.isSecureTextEntry = true
            passwordField.keyboardType = .asciiCapable
            confirmPasswordField.keyboardType = .asciiCapable
            let image = UIImage(named:"closedEye")!
            passwordEyeButton.setImage(image, for: .normal)
            confirmEyeButton.setImage(image, for: .normal)
        }
    }
    
    @IBAction func signUpClicked(_ sender: Any) {
        if !credentialsAreValid() { return }
        
        let email = "UCI"
        let password = passwordField.text!
        
        activityIndicator.startAnimating()
        
        Auth.auth().createUser(withEmail: email, password: password) { result, error in
            if error != nil {
                if let error = AuthErrorCode(rawValue: error!._code) {
                    self.displayError(title: "Error", message: error.errorMessage)
                    self.activityIndicator.stopAnimating()
                    return
                }
            }
            
            guard let fireUser = result?.user else { return }
            
            let user = User.init(id: fireUser.uid,
                                 email: email,
                                 webReg: false,
                                 school: "UCI",
                                 receiveEmails: true)
            
            UserDefaults.standard.set(true, forKey: Defaults.wasReferred)
            
            self.sendVerificationEmail(user: fireUser)
            self.createFireStoreUser(user: user, fireUser: fireUser)
        }
    }
}

extension SignUpPopUpController: UITextFieldDelegate {
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        
        if textField == emailField {
            textField.resignFirstResponder()
            passwordField.becomeFirstResponder()
        } else if textField == passwordField {
            textField.resignFirstResponder()
            confirmPasswordField.becomeFirstResponder()
        } else if textField == confirmPasswordField {
            self.view.endEditing(true)
            return true
        }
        return false
    }
}

