//
//  SignUpController.swift
//  ClassesApp
//
//  Created by Darrel Muonekwu on 3/25/20.
//  Copyright © 2020 Darrel Muonekwu. All rights reserved.
//

import UIKit
import FirebaseAuth
import FirebaseFirestore

class SignUpController: UIViewController {

    @IBOutlet weak var fullNameField: UITextField!
    @IBOutlet weak var emailField: UITextField!
    @IBOutlet weak var passwordField: UITextField!
    @IBOutlet weak var confirmPasswordField: UITextField!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    let db = Firestore.firestore()

    override func viewDidLoad(){
        super.viewDidLoad()
    }
    
    func presentHomePage() {
        let vc = storyboard?.instantiateViewController(withIdentifier: "HomePageController") as! HomePageController
        let navController = UINavigationController(rootViewController: vc)
        navController.modalPresentationStyle = .fullScreen //or .overFullScreen for transparency
        self.present(navController, animated: true, completion: nil)
    }
    
    func credentialsAreValid() -> Bool {
        if !(self.fullNameField.text!.isValidName) {
            let message = "Please enter valid first and last name. (Ex. Michael Young)"
            self.displayError(title: "Whoops.", message: message)
            return false
        }
        else if !(emailField.text!.isValidUCIEmail) {
            let message = "Email must be a valid UCI email address. Ex. panteatr@uci.edu"
            self.displayError(title: "Whoops.", message: message)
            return false
        }
        else if (passwordField.text!.count < 5 || passwordField.text!.containsWhitespace) {
            print(passwordField.text!.count < 5)
            print(passwordField.text!.containsWhitespace)
            let message = "Password must be at least 6 charaters and contain no spaces."
            self.displayError(title: "Whoops.", message: message)
            return false
        }
        else if !(passwordField.text! == confirmPasswordField.text) {
            let message = "Looks like your passwords don't match. Let's give it another shot."
            self.displayError(title: "Uh Oh.", message: message)
            return false
        }
        return true
    }
    
    @IBAction func signUpClicked(_ sender: Any) {
        if !credentialsAreValid() { return }
        
        let fullName = fullNameField.text!.separateAndFormatName()
        let email = emailField.text!
        let password = passwordField.text!
        let firstName = fullName[0]
        let lastName = fullName[1]
        
        activityIndicator.startAnimating()

        Auth.auth().createUser(withEmail: email, password: password) { result, error in
            if let error = error {
                self.displayError(error: error)
                self.activityIndicator.stopAnimating()
                return
            }
            
            guard let fireUser = result?.user else { return }
            
            let user = User.init(id: fireUser.uid,
                                 email: email,
                                 firstName: firstName,
                                 lastName: lastName,
                                 stripeId: "",
                                 webReg: false,
                                 webRegPswd: "",
                                 
                                 school: "UCI",
                                 fcm_token: "",
                                 purchaseHistory: [[ : ]],
                                 receiveEmails: true,
                                 notifications: [[ : ]]
                                 )
            
            self.createFireStoreUser(user: user)
        }
    }
    
    func createFireStoreUser(user: User) {
        
        // Add a new document with a generated ID
        let ref = db.collection("User").document(user.email)
        let user_dict = User.modelToData(user: user)
        
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
                self.presentHomePage()
            }
        }
    }
}
