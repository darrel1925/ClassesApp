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
import FirebaseFunctions

class SignUpController: UIViewController {
    
    @IBOutlet weak var fullNameField: UITextField!
    @IBOutlet weak var schoolField: UITextField!
    @IBOutlet weak var emailField: UITextField!
    @IBOutlet weak var passwordField: UITextField!
    @IBOutlet weak var confirmPasswordField: UITextField!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    let db = Firestore.firestore()
    let schoolExtDict: [String: String] = [
        "UCI": "uci",
        "UCLA": "ucla"
    ]
    
    override func viewDidLoad(){
        super.viewDidLoad()
        setUpSchoolPicker()
        setUpToolBar()
        setDelegates()
    }
    
    func setUpSchoolPicker() {
        let schoolPicker = UIPickerView()
        schoolPicker.delegate = self
        schoolField.inputView = schoolPicker
    }
    
    func setUpToolBar() {
        let toolbar = UIToolbar()
        toolbar.sizeToFit()
        
        let doneButton = UIBarButtonItem(title: "Done", style: .done, target: self, action: #selector(dismissKeyboard))
        
        toolbar.setItems([doneButton], animated: true)
        toolbar.isUserInteractionEnabled = true
        
        schoolField.inputAccessoryView = toolbar
    }
    
    func setDelegates() {
        fullNameField.delegate = self
        schoolField.delegate = self
        emailField.delegate = self
        passwordField.delegate = self
        confirmPasswordField.delegate = self
    }
    
    func presentHomePage() {
        let vc = storyboard?.instantiateViewController(withIdentifier: "HomePageController") as! HomePageController
        let navController = UINavigationController(rootViewController: vc)
        navController.modalPresentationStyle = .fullScreen //or .overFullScreen for transparency
        self.present(navController, animated: true, completion: nil)
    }
    
    @objc func dismissKeyboard() {
        view.endEditing(true)
        schoolField.resignFirstResponder()
        emailField.becomeFirstResponder()
        
    }
    
    func credentialsAreValid() -> Bool {
        if !(self.fullNameField.text!.isValidName) {
            let message = "Please enter only 1 first name and 1 last name. Thank you. (Ex. Michael Young)"
            self.displayError(title: "Whoops.", message: message)
            return false
        }
        else if !(emailField.text!.isValidSchoolEmail) {
            let message = "Email must be a valid school email address ending in 'edu' /n/n Ex. panteatr@uci.edu, bbears@ucla.edu"
            self.displayError(title: "Whoops.", message: message)
            return false
        }
        else if !(schoolField.text?.count ?? 0 > 0) {
            let message = "Please select a school. If your school is not shown, we are not supporting your campus at this time."
            self.displayError(title: "School Not Selected.", message: message)
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
        let email = emailField.text!
        let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
        let emailArray = trimmedEmail.components(separatedBy: "@") // ['pname', 'uci.edu']
        let extensionArray = emailArray[1].components(separatedBy: ".") // ['uci', 'edu']
        let schoolExtenstion = extensionArray[0]
        
        // Chose UCLA as school but has a .uci.edu email address
        if schoolExtenstion != schoolExtDict[schoolField.text!]{
            let message = "Looks like your school and email address don't match. \(schoolField.text ?? "") should have a '.\(schoolExtDict[schoolField.text!] ?? "")' extension."
            self.displayError(title: "Mismatch", message: message)
            return false
        }
        
        return true
    }
    
    func createFireStoreUser(user: User) {
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
                self.presentHomePage()
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
    
    @IBAction func signUpClicked(_ sender: Any) {
        if !credentialsAreValid() { return }
        
        let fullName = fullNameField.text!.separateAndFormatName()
        let school = schoolField.text!
        let email = emailField.text!
        let password = passwordField.text!
        let firstName = fullName[0]
        let lastName = fullName[1]
        
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
                                 firstName: firstName,
                                 lastName: lastName,
                                 webReg: false,
                                 school: school,
                                 credits: 2,
                                 receiveEmails: true)
            
            self.createFireStoreUser(user: user)
        }
    }
}

extension SignUpController: UITextFieldDelegate {
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField == fullNameField {
            textField.resignFirstResponder()
            schoolField.becomeFirstResponder()
        } else if textField == schoolField {
            textField.resignFirstResponder()
            emailField.becomeFirstResponder()
        } else if textField == emailField {
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

extension SignUpController: UIPickerViewDelegate, UIPickerViewDataSource {
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return AppConstants.supported_schools.count
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return AppConstants.supported_schools[row]
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        schoolField.text = AppConstants.supported_schools[row]
    }
}
