//
//  AddClassController.swift
//  ClassesApp
//
//  Created by Darrel Muonekwu on 3/30/20.
//  Copyright © 2020 Darrel Muonekwu. All rights reserved.
//

import UIKit
import Socket

class AddClassController: UIViewController {
    
    @IBOutlet weak var checkAvailabilityButton: RoundedButton!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var addClassLabel: UILabel!
    @IBOutlet weak var trackClassesButton: RoundedButton!
    @IBOutlet weak var statusTitle: UILabel!
    @IBOutlet weak var courseCodeField: UITextField!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var backgroundView: UIView!
    @IBOutlet weak var stackView: UIStackView!
    @IBOutlet weak var quarterLabel: UILabel!
    
    var courseCodes = [String]()
    var courseStatus = [String]()
    var currentResponse = ""
    var currentClass = ""
    
    /*
     ADD A HOW IT WORKS MENU TAB WITH VIEW CONTROLLERS AND ICONS TO SHOW WHAT THE APP IS FOR
     */
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
        addClassLabel.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(addClassClicked)))
        addClassLabel?.layer.masksToBounds = true
        addClassLabel.isHidden = true
        addClassLabel.layer.cornerRadius = 10
        
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
    
    @objc func dismissKeyboard() {
        view.endEditing(true)
    }
    
    func updateUI(withResponce response: String) {
        print("got response \(response) and currClassIs \(currentClass)")
        let chosenClass = courseCodeField.text ?? "no Text"
        switch response {
        case "OPEN":
            animateAddButtonIn()
            backgroundView.backgroundColor = #colorLiteral(red: 0.4574845033, green: 0.8277172047, blue: 0.4232197912, alpha: 0.2520467252)
            statusTitle.text = "\(chosenClass) is Open"
            break
        case "Waitl":
            animateAddButtonIn()
            backgroundView.backgroundColor = #colorLiteral(red: 0.8425695398, green: 0.8208485929, blue: 0, alpha: 0.248053115)
            statusTitle.text = "\(chosenClass) is on Waitlist"
            break
        case "FULL":
            animateAddButtonIn()
            backgroundView.backgroundColor = #colorLiteral(red: 0.8103429773, green: 0.08139390926, blue: 0.116439778, alpha: 0.2456195088)
            statusTitle.text = "\(chosenClass) is on Full"
            break
        case "NewOnly":
            animateAddButtonIn()
            backgroundView.backgroundColor = #colorLiteral(red: 0, green: 0.6157837616, blue: 0.9281850962, alpha: 0.2466803115)
            statusTitle.text = "\(chosenClass) is New Only"
            break
        default:
            animateAddButtonOut()
            backgroundView.backgroundColor = #colorLiteral(red: 0.505957987, green: 0.01517132679, blue: 0.8248519059, alpha: 0.2461187101)
            statusTitle.text = "Error: \(chosenClass) is not offered this quarter"
            break
        }
    }
    
    func animateAddButtonIn() {
        UIView.animate(withDuration: 0.5) {
            self.addClassLabel.isHidden = false
        }
    }
    
    func animateAddButtonOut() {
        UIView.animate(withDuration: 0.5) {
            self.addClassLabel.isHidden = true
        }
    }
    
    func updateTrackClassLabel() {
        if currentClass.count == 1 {
            trackClassesButton.titleLabel?.text = "Track \(courseCodes.count) class"
        }
        else {
            trackClassesButton.titleLabel?.text = "Track \(courseCodes.count) classes"
        }
    }
    
    func makeConnection(withCourseCode code: String, withAction action: String, withString input: String) {
        var mySocket: Socket
        
        do {
            print("will create")
            mySocket = try Socket.create()
            mySocket.readBufferSize = 32768
            print("created")
            do {
                let server_ip = AppConstants.server_ip
                let server_port = AppConstants.server_port
                try mySocket.connect(to: server_ip, port: Int32(server_port))
                
                
                do {
                    try mySocket.write(from: input)
                    
                    
                    if action == "get"{
                        do {
                            var data: Data = Data()
                            _ = try mySocket.read(into: &data)
                            let response = String(data: data, encoding: .utf8)
                            self.addClassLabel.text = "Add \(code)"
                            updateUI(withResponce: response!)
                            currentResponse = response!
                            currentClass = code
                            activityIndicator.stopAnimating()
                            print("updated vals \(currentResponse) | \(currentClass)")
                            tableView.reloadData()
                            
                            return
                        }
                        catch {
                            let message = "Looks like there was an issue. If this continues, try opening and closing the app!"
                            self.displayError(title: "Connection Error", message: message)
                            activityIndicator.stopAnimating()
                            mySocket.close()
                        }
                    }
                    activityIndicator.stopAnimating()
                    mySocket.close()
                }
                catch { // problem with code writing data back
                    let message = "This isn't your fault this one's on us. We're probably taking this time to make TrackMy a better app for you! Try again later while we work to get this fixed!"
                    self.displayError(title: "Connection Error", message: message)
                    activityIndicator.stopAnimating()
                    mySocket.close()}
            }
            catch { // server is not up and runnung
                let message = "This isn't your fault this one's on us. We're probably taking this time to make TrackMy a better app for you! Try again later while we work to get this fixed!"
                self.displayError(title: "Network Error", message: message)
                activityIndicator.stopAnimating()
                mySocket.close()}
        }
        catch { // problem with users internet connection
            let message = "Looks like there is an issue. Try checking your internet connection and try again."
            self.displayError(title: "Connection Error", message: message)
            activityIndicator.stopAnimating()}
        
        activityIndicator.stopAnimating()
        self.currentResponse = ""
        self.currentClass = ""
        print("vals reset")
        tableView.reloadData()
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
        
        dismissKeyboard()
        let email = UserService.user.email
        let quarter = "spring"
        let year = "2020"
        let courseCode = courseCodeField.text!
        let school = UserService.user.school
        let input = "\(action)\(email),\(quarter),\(year),\(courseCode),\(school),"
        
        makeConnection(withCourseCode: courseCode, withAction: action, withString: input)
    }
    
    @IBAction func checkAvailabilityClicked(_ sender: Any) {
        print("starting monitor")
        activityIndicator.startAnimating()
        sendRequest(withAction: "get")
    }
    
    @objc func addClassClicked() {
        if currentResponse == "" { return }
        if currentResponse == "Error" {
            tableView.reloadData()
            return }
        
        if courseCodes.contains(currentClass) {
            print("current responce is \(currentClass)")
            let message = "You've already added this course!"
            self.displayError(title: "Whoops.", message: message)
            return }
        
//        sendRequest(withAction: "add") // <-- remove later
        
        courseCodes.append(currentClass)
        courseStatus.append(currentResponse)
        tableView.reloadData()
        
        updateTrackClassLabel()
    }
    
    @IBAction func trackClassesClicked(_ sender: Any) {
        
        if courseCodes.count == 0 {
            let message = "It looks like you haven't added any classes yet. Check the availibility of your class and the click 'Add Class' before you begin tracking"
            self.displayError(title: "No Classes Added.", message: message)
        }
        
        StripeCart.clearCart()
        for courseCode in courseCodes {
            StripeCart.addItemToCart(item: courseCode)
        }
        
        let checkOutVC = storyboard?.instantiateViewController(withIdentifier: "CheckOutController") as! CheckOutController
        checkOutVC.modalPresentationStyle = .overFullScreen
        self.present(checkOutVC, animated: true, completion: nil)
        
        // present cart
        // once their info in is
        
        // 1. track the courses
        // 2. process payment
        // 3.  if payment goes through
        // 3.1 dismiss
        // 4. if payment method fails
        // 4.1 remove courses from being tracked
        
        // sendRequest(withAction: "add")
    }
}

extension AddClassLauncher: UITextFieldDelegate {
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        self.view.endEditing(true)
        return false
    }
}

extension AddClassController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return courseStatus.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let row = indexPath.row
        let cell = tableView.dequeueReusableCell(withIdentifier: "TrackedCell") as! TrackedCell
        
        print(row)
        print(self.courseStatus)
        print(self.courseCodes)
        
        cell.statusLabel.text = self.courseStatus[row]
        cell.courseCodeLabel.text = self.courseCodes[row]
        updateCellColor(withCell: cell, withResponce: courseStatus[row], atRow: row)
        updateCellContentViewColor(withCell: cell, withResponce: courseStatus.last ?? "")
        cell.cellView.layer.cornerRadius = 5
//        cell.contentView.layer.cornerRadius = 5
        return cell
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        print("hi1")
        if editingStyle == .delete {
            print("Deleted")
            
            self.courseCodes.remove(at: indexPath.row)
            self.courseStatus.remove(at: indexPath.row)
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
        case "OPEN":
            cell.cellView.backgroundColor = #colorLiteral(red: 0.4574845033, green: 0.8277172047, blue: 0.4232197912, alpha: 0.3437749601)
            
        case "Waitl":
            cell.cellView.backgroundColor = #colorLiteral(red: 0.8425695398, green: 0.8208485929, blue: 0, alpha: 0.3)
        case "FULL":
            cell.cellView.backgroundColor = #colorLiteral(red: 0.8103429773, green: 0.08139390926, blue: 0.116439778, alpha: 0.3432383187)
        case "NewOnly":
            cell.cellView.backgroundColor = #colorLiteral(red: 0, green: 0.6157837616, blue: 0.9281850962, alpha: 0.3187150559)
        default:
            cell.cellView.backgroundColor = #colorLiteral(red: 0.505957987, green: 0.01517132679, blue: 0.8248519059, alpha: 0.3333166933)
        }
    }
    
    func updateCellContentViewColor(withCell cell: TrackedCell, withResponce response: String) {
        /*
         Updates the color of the backgrounds of the cells in the table view
         */
        if currentResponse == "" { return }
        
        switch currentResponse {
        case "OPEN":
            cell.contentView.backgroundColor = #colorLiteral(red: 0.4574845033, green: 0.8277172047, blue: 0.4232197912, alpha: 0.2520467252)
        case "Waitl":
            cell.contentView.backgroundColor = #colorLiteral(red: 0.8425695398, green: 0.8208485929, blue: 0, alpha: 0.248053115)
        case "FULL":
            cell.contentView.backgroundColor = #colorLiteral(red: 0.8103429773, green: 0.08139390926, blue: 0.116439778, alpha: 0.2456195088)
        case "NewOnly":
            cell.contentView.backgroundColor = #colorLiteral(red: 0, green: 0.6157837616, blue: 0.9281850962, alpha: 0.2466803115)
        default:
            cell.contentView.backgroundColor = #colorLiteral(red: 0.505957987, green: 0.01517132679, blue: 0.8248519059, alpha: 0.2461187101)
            
        }
    }
}
