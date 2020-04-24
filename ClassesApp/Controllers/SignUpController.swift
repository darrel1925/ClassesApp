//
//  SignUpController.swift
//  ClassesApp
//
//  Created by Darrel Muonekwu on 3/25/20.
//  Copyright © 2020 Darrel Muonekwu. All rights reserved.
//
// https://www.termsfeed.com/privacy-policy/442d8d1d2c1816301827f97bd4302e67
// https://www.termsfeed.com/terms-conditions/dbbbc444ec3b39f928157c712c5f978a
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
    @IBOutlet weak var textView: UITextView!
    
    let db = Firestore.firestore()
    let schoolExtDict: [String: String] = [
        "UCI": "uci",
        "UCLA": "ucla"
    ]
    
    var termsLowerBound: Int!
    var privacyLowerBound: Int!
    
    override func viewDidLoad(){
        super.viewDidLoad()
        setUpSchoolPicker()
        setUpToolBar()
        setDelegates()
        setUpTextView()
        
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
    
    func setUpTextView() {
        self.textView.delegate = self
        let labelText = "By tapping Sign Up, you agree to our Terms and Conditions and Privacy Statement"
        let termsString = NSMutableAttributedString(string: labelText)
        
        let termsRange = termsString.mutableString.range(of: "Terms and Conditions")
        let privacyRange = termsString.mutableString.range(of: "Privacy Statement")
        
        termsLowerBound = termsRange.lowerBound
        privacyLowerBound = privacyRange.lowerBound
        
        termsString.addAttribute(.link, value: "https://google.com", range: termsRange)
        termsString.addAttribute(.link, value: "https://google.com", range: privacyRange)
        
//        let font  = UIFont()
//        let color = UIColor.lightGray
        
//        termsString.setFontFace(font: font, color: color)
        
        textView.attributedText = termsString
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
    
    func presentVerificationSentAlert(user: FirebaseAuth.User) {
        let message = "A verification email has been send to \(user.email!). Please verifiy your account then log in."
        let alert = UIAlertController(title: "Verification Email Sent", message: message, preferredStyle: .alert)
        
        let okayAction = UIAlertAction(title: "Okay", style: .default, handler: {_ in
            let logInVC = self.storyboard?.instantiateViewController(identifier: "LogInController") as! LogInController
            logInVC.emailText = user.email!
            self.present(logInVC, animated: true, completion: nil)
        })
        
        alert.addAction(okayAction)
        present(alert, animated: true, completion: nil)
    }
    
    func sendVerificationEmail(user: FirebaseAuth.User) {
        user.sendEmailVerification { err in
            if let _ = err {
                let message = "Error sending your verification email. Head over to the login screen to log in."
                self.displayError(title: "Verification Email Error", message: message)
                return
            }
            print("verification email sent")
            self.presentVerificationSentAlert(user: user)
        }
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
                self.sendVerificationEmail(user: fireUser)
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
            
            self.createFireStoreUser(user: user, fireUser: fireUser)
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

extension SignUpController: UITextViewDelegate {
    
    func textView(_ textView: UITextView, shouldInteractWith URL: URL, in characterRange: NSRange, interaction: UITextItemInteraction) -> Bool {
        print(characterRange.lowerBound)
        if (characterRange.lowerBound == termsLowerBound) {// == "Terms and Conditions"
            presentTermsController()
        }
        else if (characterRange.lowerBound == privacyLowerBound){ // "Privacy Statment"
            presentPrivacyController()
        }
        
        return false
    }
}
