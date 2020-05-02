//
//  AddClassController.swift
//  ClassesApp
//
//  Created by Darrel Muonekwu on 3/30/20.
//  Copyright © 2020 Darrel Muonekwu. All rights reserved.
//

import UIKit
import Socket
import AudioToolbox
import FirebaseAuth
import FirebaseFirestore

class AddClassController: UIViewController {
    
    @IBOutlet weak var checkAvailabilityButton: RoundedButton!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var trackClassesButton: RoundedButton!
    @IBOutlet weak var statusTitle: UILabel!
    @IBOutlet weak var courseCodeField: UITextField!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var backgroundView: UIView!
    @IBOutlet weak var stackView: UIStackView!
    @IBOutlet weak var quarterLabel: UILabel!
    
    var courses = [Course]()


    // Change store to get credits or go premium
    override func viewDidLoad() {
        super.viewDidLoad()
        quarterLabel.text = AppConstants.quarter.capitalizingFirstLetter()
        setUpButtons()
        setUpTableView()
        setUpGestures()
    }
    
    func setUpTableView() {
        tableView.delegate = self
        tableView.dataSource = self
    }
    
    func setUpButtons() {
        checkAvailabilityButton.layer.cornerRadius = 10
        checkAvailabilityButton.titleLabel?.numberOfLines = 1
        checkAvailabilityButton.titleLabel?.adjustsFontSizeToFitWidth = true
        checkAvailabilityButton.titleLabel?.lineBreakMode = .byClipping
    }
    
    func setUpGestures() {
        let tap1: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(UIInputViewController.dismissKeyboard))
        let tap2: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(UIInputViewController.dismissKeyboard))
        let tap3: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(UIInputViewController.dismissKeyboard))
        let swipe1: UISwipeGestureRecognizer = UISwipeGestureRecognizer(target: self, action: #selector(UIInputViewController.dismissKeyboard))
        let swipe2: UISwipeGestureRecognizer = UISwipeGestureRecognizer(target: self, action: #selector(UIInputViewController.dismissKeyboard))
        let swipe3: UISwipeGestureRecognizer = UISwipeGestureRecognizer(target: self, action: #selector(UIInputViewController.dismissKeyboard))
        
        swipe1.direction = .down
        swipe2.direction = .down
        swipe3.direction = .down
        
        backgroundView.addGestureRecognizer(tap1)
        backgroundView.addGestureRecognizer(swipe1)
        stackView.addGestureRecognizer(swipe2)
        stackView.addGestureRecognizer(tap2)
        tableView.addGestureRecognizer(swipe3)
        tableView.addGestureRecognizer(tap3)
    }
    
    func presentCart() {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let cartVc = storyboard.instantiateViewController(withIdentifier: "CheckOutController") as! CheckOutController
        self.present(cartVc, animated: true, completion: nil)
    }
    
    func presnentAddToList(course: Course) {
        let addToListVC = AddToListController()
        addToListVC.modalPresentationStyle = .overFullScreen
        addToListVC.course = course
        addToListVC.addClassVC = self
        self.present(addToListVC, animated: true, completion: nil)
    }
    
    func presentPaymentErrorAlert() {
        print("error alert presenting")
        let message = "There was an error while attempting to track your classes. Your credits have not been affected."
        
        let alertController = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
        let okay = UIAlertAction(title: "Okay", style: .default, handler: nil)
        
        alertController.addAction(okay)
        self.present(alertController, animated: true)

    }
    
    func presentSuccessAlert() {
        ServerService.addToTrackedClasses(courses: courses)
        
        AudioServicesPlaySystemSound(1519) // Actuate "Peek" feedback (weak boom)
        let message = "You're all set.\n\nNote: It may take up to 1 minute to begin tracking your class."

        let alertController = UIAlertController(title: "Success!", message: message, preferredStyle: .alert)
        let okay = UIAlertAction(title: "Okay", style: .default, handler: {(action) in
            self.navigationController?.popViewController(animated: true)
        })
        
        alertController.addAction(okay)
        self.present(alertController, animated: true)
    }
    
    func addClasses(dispatchGroup dg: DispatchGroup) -> Bool {
        dg.enter()

        for course in courses {
            if !ServerService.addClassToFirebase(withCourse: course, viewController: self) {
                ServerService.dispatchGroup.notify(queue: .main) {
                    print("is false")
                    // error occured, remove classes
                    ServerService.removeClassesFromFirebase(withCourseCodes: Course.getCodes(courses: self.courses))
                    self.activityIndicator.stopAnimating()
                    self.presentPaymentErrorAlert()
                    dg.leave()
                }
            }
        }
        dg.leave()
        return true
    }
    
    func trackClasses() {
        let dg = DispatchGroup()
        if !addClasses(dispatchGroup: dg) { return }
        
        dg.notify(queue: .main) {
            print("dispatched finished")

            self.presentSuccessAlert()
        }
    }
    
    @objc func dismissKeyboard() {
        view.endEditing(true)
    }
    
    func updateUI(withResponce response: String) {
        print("got response \(response)")
        let chosenClass = courseCodeField.text ?? "no Text"
        switch response {
        case Status.OPEN:
            backgroundView.backgroundColor = #colorLiteral(red: 0.4574845033, green: 0.8277172047, blue: 0.4232197912, alpha: 0.2520467252)
            statusTitle.text = "\(chosenClass) is Open"
            break
        case Status.Waitl:
            backgroundView.backgroundColor = #colorLiteral(red: 0.8425695398, green: 0.8208485929, blue: 0, alpha: 0.248053115)
            statusTitle.text = "\(chosenClass) is on Waitlist"
            break
        case Status.FULL:
            backgroundView.backgroundColor = #colorLiteral(red: 0.8103429773, green: 0.08139390926, blue: 0.116439778, alpha: 0.2456195088)
            statusTitle.text = "\(chosenClass) is Full"
            break
        case Status.NewOnly:
            backgroundView.backgroundColor = #colorLiteral(red: 0, green: 0.6157837616, blue: 0.9281850962, alpha: 0.2466803115)
            statusTitle.text = "\(chosenClass) is New Only"
            break
        default:
            backgroundView.backgroundColor = #colorLiteral(red: 0.505957987, green: 0.01517132679, blue: 0.8248519059, alpha: 0.2461187101)
            statusTitle.text = "Error: \(chosenClass) is not offered this quarter"
            break
        }
    }
    
    func updateTrackClassLabel() {
        if courses.count == 1 {
            trackClassesButton.titleLabel?.text = "Track \(courses.count) class"
        }
        else {
            trackClassesButton.titleLabel?.text = "Track \(courses.count) classes"
        }
    }
    
    func makeConnection(withCourseCode code: String, withAction action: String, withString input: String) {
        
        let serverResponse = ServerService.makeConnection(withAction: action, withInput: input)
        
        switch serverResponse {
        case Status.Error:
            let message = "\(code) is not offered. Double check that you typed in your code correctly."
            self.displayError(title: "Class Not Offered", message: message)
            activityIndicator.stopAnimating()
            return
        case "ConnectionError1": // could not read what was returned from server
            let message = "Looks like there was an issue. If this continues, try opening and closing the app!"
            self.displayError(title: "Connection Error", message: message)
            activityIndicator.stopAnimating()
            return
        case "ConnectionError2": // problem with code writing data back
            let message = "This isn't your fault this one's on us. We're probably taking this time to make TrackMy a better app for you! Try again later while we work to get this fixed!"
            self.displayError(title: "Connection Error", message: message)
            activityIndicator.stopAnimating()
            return
        case "NetworkError1": // server is not up and runnung | <-- might be user's interner connection
            let message = "This isn't your fault this one's on us. We're probably taking this time to make TrackMy a better app for you! Try again later while we work to get this fixed!"
            self.displayError(title: "Network Error", message: message)
            activityIndicator.stopAnimating()
            return
        case "NetworkError2": // problem with users internet connection
            let message = "Looks like there is an issue. Try checking your internet connection and try again."
            self.displayError(title: "Network Error", message: message)
            activityIndicator.stopAnimating()
            return
        default:
            break
        }
        
        let course = Course(serverInput: serverResponse)
        let status = course.status
        
        if [Status.Waitl, Status.OPEN, Status.FULL, Status.NewOnly].contains(status) {
            print("updated vals \(course.status) | \(course.course_code)")
            activityIndicator.stopAnimating()
            presnentAddToList(course: course)
            return
        }
        
        activityIndicator.stopAnimating()
        tableView.reloadData()
    }
    
    func alreadyTrackingClasses() -> Bool {
        for code in Course.getCodes(courses: courses) {
            if UserService.user.courseCodes.contains(code){
                let message = "You are already tracking course \(code). Remove this course from the list before continuing."
                displayError(title: "Duplicate Class", message: message)
                return true
            }
        }
        return false
    }
    
    func sendRequest(withAction action: String) {
        if courseCodeField.text?.isEmpty ?? true {
            activityIndicator.stopAnimating()
            let message = "Looks like you forgot to enter your course code. Let's try again!"
            self.displayError(title: "Uh Oh.", message: message)
            return }
        
        if courseCodeField.text?.count != 5  || courseCodeField.text?.isOnlyNumeric ?? true {
            activityIndicator.stopAnimating()
            let message = "Make sure you enter a 5 digit course! Ex. 34250 or 14723"
            self.displayError(title: "Invalid Entry.", message: message)
            return }
        
        if Course.getCodes(courses: courses).contains(courseCodeField.text ?? "") {
            activityIndicator.stopAnimating()
            let message = "You've already added this course! Check the availibility of a different class before adding again."
            self.displayError(title: "Duplicate Course.", message: message)
            return }
        
        dismissKeyboard()
        let courseCode = courseCodeField.text!
        let input = ServerService.constuctInput(withAction: action, withCode: courseCode)
        
        makeConnection(withCourseCode: courseCode, withAction: action, withString: input)
    }
    
    @IBAction func checkAvailabilityClicked(_ sender: Any) {
        activityIndicator.startAnimating()
        sendRequest(withAction: "get")
    }

    
    @IBAction func trackClassesClicked(_ sender: Any) {

        if courses.count == 0 {
            let message = "Tap 'Check Availibility' before trying to track your classes"
            self.displayError(title: "No Classes Added.", message: message)
            return
        }
        
        if alreadyTrackingClasses() { return }
                
        var courseDict: [String: String] = [:]
        for i in stride(from: 0, to: courses.count, by: 1) {
            courseDict.updateValue(courses[i].status, forKey: courses[i].course_code)
        }
        
        trackClasses()
    }
}

extension AddClassController: UITextFieldDelegate {
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        self.view.endEditing(true)
        return false
    }
}

extension AddClassController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return courses.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let row = indexPath.row
        let cell = tableView.dequeueReusableCell(withIdentifier: "TrackedCell") as! TrackedCell
        let course = courses[row]
        
        cell.statusLabel.text = course.status
        cell.courseCodeLabel.text = "\(course.course_name) \(course.course_type) \(course.section)"
        updateCellColor(withCell: cell, withResponce: course.status, atRow: row)
        cell.cellView.layer.cornerRadius = 5
        return cell
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {

            self.courses.remove(at: indexPath.row)
            updateTrackClassLabel()
            
            self.tableView.deleteRows(at: [indexPath], with: .automatic)
        }
    }
    
    func updateCellColor(withCell cell: TrackedCell, withResponce response: String, atRow row: Int) {
        /*
         Updates the color of the rounded views the cells in the table view
         */
        print("got response \(response)")
        if response == "" { return }
        switch response {
        case Status.OPEN:
            cell.cellView.backgroundColor = #colorLiteral(red: 0.4574845033, green: 0.8277172047, blue: 0.4232197912, alpha: 0.2520467252)
        case Status.Waitl:
            cell.cellView.backgroundColor = #colorLiteral(red: 0.8425695398, green: 0.8208485929, blue: 0, alpha: 0.248053115)
        case Status.FULL:
            cell.cellView.backgroundColor = #colorLiteral(red: 0.8103429773, green: 0.08139390926, blue: 0.116439778, alpha: 0.2456195088)
        case Status.NewOnly:
            cell.cellView.backgroundColor = #colorLiteral(red: 0, green: 0.6157837616, blue: 0.9281850962, alpha: 0.2466803115)
        default:
            cell.cellView.backgroundColor = #colorLiteral(red: 0.505957987, green: 0.01517132679, blue: 0.8248519059, alpha: 0.2461187101)
        }
    }
}
