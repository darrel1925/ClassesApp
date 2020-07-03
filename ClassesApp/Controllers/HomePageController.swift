//
//  HomePageController.swift
//  ClassesApp
//
//  Created by Darrel Muonekwu on 3/25/20.
//  Copyright © 2020 Darrel Muonekwu. All rights reserved.
//

import UIKit
import FirebaseCrashlytics
import FirebaseAuth
import FirebaseFirestore
import MessageUI

class HomePageController: UIViewController {
    
    @IBOutlet weak var quarterLabel: UILabel!
    @IBOutlet weak var backgroundView: RoundedView!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var leftForegroundView: UIView!
    @IBOutlet weak var unlimitedLabel: UILabel!
    @IBOutlet weak var courseCodeLabel: UILabel!
    
    let transition = SlideInTransition()
    
    var noClassLabel: UILabel!
    var addClassesisPresented = false
    var labelHasBeenPresented = false
    var refreshControl: UIRefreshControl?
    var courses = [Course]()
    
    var lastClick: TimeInterval!
    var lastIndexPath: IndexPath!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setUpAddLabel()
        setLabels()
        setUpNavController()
        setUpTableView()
        setUpGestures()
        setScreenName()
        print("view did load")

    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        setLabels()
        refreshTableView()

        UserService.checkForShortLink()
        UserService.setFCM()
        UserService.resetBadgeCount()
        UserService.setAppVersion()
        UserService.setDateJoined() // <-- will only need temporarily
        handleUpdatePrompt()
        handleWhatsNewController()
        handleShowDirections()
        print("view did appear")
    }

    func handleWhatsNewController() {
        /* Displays whats new controller if the user has not seen the controller AND the user
        has the most current version of the app
         !!! Need to update most current_app_version in AppConstants !!! */
        
        print("UserService.user.seenWhatsNew",  UserService.user.seenWhatsNew)
        
        // if I have have seen the whats new page
        if UserService.user.seenWhatsNew  { return }
        
        ServerService.getCurrentAppStoreVersion { (appStoreVersion, success) in
            // if I could not get version from appstore
            if !success { return }
            // if i do not have the apps most up to date version
            if appStoreVersion != App.version { return }
            
            // if i do have the current version
            DispatchQueue.main.async {
                self.presentWhatsNew()
                let db = Firestore.firestore()
                let docRef = db.collection(DataBase.User).document(UserService.user.email)
                docRef.updateData([DataBase.seen_whats_new : true])
            }
        }
    }
    
    func handleUpdatePrompt() {
        if !AppConstants.should_prompt_update { return }
        
        let frequency = AppConstants.should_prompt_update_frequency
        let promptForUpdate = UserDefaults.standard.integer(forKey: Defaults.promptForUpdate)
        
        ServerService.getCurrentAppStoreVersion { (appStoreVersion, success) in
            // if I could not get version from appstore
            if !success { return }
            // if i do have the apps most up to date version
            if appStoreVersion == App.version { return }
            print("promptForUpdate:", promptForUpdate, "is up to date:", appStoreVersion == App.version)

            UserDefaults.standard.set(promptForUpdate + 1, forKey: Defaults.promptForUpdate)
            
            if promptForUpdate % frequency == 0 {
                DispatchQueue.main.async {
                    self.presentUpdateAvailible()
                }
            }
        }
    }
    
    func handleShowDirections() {
        if UserService.user.seenHomeTapDirections { return }
        if UserService.user.courseCodes.count != 1 { return }
        
        Animations.animateHomeTapDirections(HomeViewController: self)
        let db = Firestore.firestore()
        let docRef = db.collection(DataBase.User).document(UserService.user.email)
        docRef.updateData([DataBase.seen_home_tap_directions  : true])
    }
    
//    func checkForUpdate() {
//        _ = try? ServerService.isUpdateAvailable(completion: { (update, error) in
//            if let error = error {
//                print("error", error)
//            } else if let update = update {
//                print("needs update", update)
//                DispatchQueue.main.async {
//
//                }
//            }
//        })
//    }
    
    func setScreenName() {
        Stats.setScreenName(screenName: "HomePage", screenClass: "HomePageController")
    }
    
    func setLabels() {
    
        let school = UserService.user.school
        let quarter = AppConstants.quarter.capitalizingFirstLetter()
        let year = AppConstants.year.capitalizingFirstLetter()
        quarterLabel.text = "\(school) \(quarter) \(year)"
        
        if !UserService.user.hasPremium {
            unlimitedLabel.isHidden = true
        }
        else {
            unlimitedLabel.isHidden = false
        }
    }
    
    func setUpGestures() {
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(didSwipeOnView))
        leftForegroundView.addGestureRecognizer(panGesture)
    }
    
    func setUpTableView() {
        self.tableView.delegate = self
        self.tableView.dataSource = self
        refreshControl = UIRefreshControl()
        refreshControl?.tintColor = .black
        refreshControl?.addTarget(self, action: #selector(refreshTableView), for: .valueChanged)
        tableView.addSubview(refreshControl!)
        
        toggleNoClassLabel()
    }
    
    func setUpNavController() {
        self.navigationController?.navigationBar.tintColor = .black
        
        self.navigationItem.largeTitleDisplayMode = .always
        self.navigationController?.navigationBar.prefersLargeTitles = true
    }
    
    func removeClass(atIndexPath indexPath: IndexPath) {
        print("indexPath \(indexPath) course len \(self.courses.count) course \(self.courses[indexPath.row].code)")

        ServerService.removeClassesFromFirebase(withCourseCodes: [self.courses[indexPath.row].code], completion: {
            print("indexPath \(indexPath) course len \(self.courses.count) course \(self.courses[indexPath.row].code)")
            self.courses.remove(at: indexPath.row)
            self.tableView.deleteRows(at: [indexPath], with: .automatic)
            self.toggleNoClassLabel()
        })

    }
    
    func presentUpdateAvailible() {
        let message = "An update is availible with the newest features and fixes to avoid problems that may occur with older versions."
        let alert = UIAlertController(title: "Time To Update", message: message, preferredStyle: .alert)
        let updateAction = UIAlertAction(title: "Update", style: .default) { (_) in
            if let url = URL(string: "itms-apps://itunes.apple.com/app/id\(ReferralLink.appStoreID)"),
                UIApplication.shared.canOpenURL(url)
            {
                UIApplication.shared.open(url, options: [:], completionHandler: nil)
            }
            UserDefaults.standard.set(0, forKey: Defaults.promptForUpdate)
            ServerService.updateUser(atKey: DataBase.prompt_update_count, withValue: 0)

            print("navigate to app store")
            if AppConstants.force_update {
                self.presentUpdateAvailible()
            }
        }
        
        alert.addAction(updateAction)
        
        present(alert, animated: true)
    }
    
    func presentWhatsNew() {
        let vc = self.storyboard?.instantiateViewController(withIdentifier: "WhatsNewController") as! WhatsNewController
        vc.modalPresentationStyle = .overFullScreen
        self.present(vc, animated: true, completion: nil)
        
    }
    
    func presentNotifications() {
        let vc = storyboard?.instantiateViewController(withIdentifier: "NotificationController") as! NotificationController
        let navController = UINavigationController(rootViewController: vc)
        navController.modalPresentationStyle = .fullScreen
        self.present(navController, animated: true, completion: nil)
    }
    
    func presentSettings() {
        let vc = storyboard?.instantiateViewController(withIdentifier: "SettingsController") as! SettingsController
        let navController = UINavigationController(rootViewController: vc)
        navController.modalPresentationStyle = .fullScreen
        self.present(navController, animated: true, completion: nil)
    }
    
    func presentStore() {
        let vc = storyboard?.instantiateViewController(withIdentifier: "StoreController") as! StoreController
        let navController = UINavigationController(rootViewController: vc)
        navController.modalPresentationStyle = .fullScreen
        self.present(navController, animated: true, completion: nil)
    }
    
    func presentAddClassesController() {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: "AddClassController") as! AddClassController
        navigationController?.pushViewController(vc, animated: true)
    }
    
    func presentShareController() {
        let vc = storyboard?.instantiateViewController(withIdentifier: "ShareController") as! ShareController
        let navController = UINavigationController(rootViewController: vc)
        navController.modalPresentationStyle = .fullScreen
        self.present(navController, animated: true, completion: nil)
    }
    
    func presentHowItWorks() {
        let vc = storyboard?.instantiateViewController(withIdentifier: "PageController") as! PageController
        vc.modalPresentationStyle = .fullScreen
        self.present(vc, animated: true, completion: nil)
    }
    
    func presentCredits() {
        let vc = storyboard?.instantiateViewController(withIdentifier: "CreditsController") as! CreditsController
        let navController = UINavigationController(rootViewController: vc)
        navController.modalPresentationStyle = .fullScreen
        self.present(navController, animated: true, completion: nil)
    }
    
    func presentClassDetailsController(course: Course, indexPath: IndexPath) {
        let vc = self.storyboard?.instantiateViewController(withIdentifier: "ClassDetailsController") as! ClassDetailsController
        vc.modalPresentationStyle = .overFullScreen
        vc.course = course
        vc.indexPath = indexPath
        vc.homeVC = self
        self.present(vc, animated: true, completion: nil)
    }
    
    func presentEmailSupport() {
        let vc = self.storyboard?.instantiateViewController(withIdentifier: "EmailSupportController") as! EmailSupportController
        let navController = UINavigationController(rootViewController: vc)
        navController.modalPresentationStyle = .fullScreen
        self.present(navController, animated: true, completion: nil)
    }
    
    func presentVerificationSentAlert() {
        let message = "Click below to resend your email verification.\n\nNote: YOU MAY NEED TO RESTART THE APP IF YOU JUST VERIFIED."
        let alert = UIAlertController(title: "Email Not Verified.", message: message, preferredStyle: .alert)
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .default, handler: nil)
        let resendAction = UIAlertAction(title: "Resend", style: .default, handler: { _ in
            self.sendVerificationEmail()
        })
        
        alert.addAction(cancelAction)
        alert.addAction(resendAction)
        present(alert, animated: true, completion: nil)
    }
    
    func sendVerificationEmail() {
        guard let user = Auth.auth().currentUser else { return }
        
        user.sendEmailVerification { err in
            if let _ = err {
                let message = "Error sending your verification email. Sorry about that. Try restarting the app or contacting customer support!"
                self.displayError(title: "Verification Email Error", message: message)
                return
            }
            
            let message = "A verification email is on its way to \(UserService.user.email)!"
            self.displayError(title: "Email Sent", message: message)
        }
    }
    
    func emailIsVerified() -> Bool {
        if UserService.user.isEmailVerified { return true }
        
        guard let user = Auth.auth().currentUser else { return false }
        user.reload(completion: nil)
        
        if user.isEmailVerified {
            let db = Firestore.firestore()
            let docRef = db.collection(DataBase.User).document(UserService.user.email)
            docRef.updateData([DataBase.is_email_verified: true])
            Stats.logEmailVerified()
            return true
        }
        
        return false
    }
    
    func reloadUser() {
        /*
         If user just verified their email without closing the app, this will refresh their user object to reflect that
         */
        if UserService.user.isEmailVerified { return }
        guard let user = Auth.auth().currentUser else { return }
        user.reload(completion: nil)
    }
    
    func toggleNoClassLabel(){
        if self.courses.count > 0 {
            self.noClassLabel.isHidden = true
        }
        else {
            if !self.labelHasBeenPresented { self.setUpAddLabel() }
            self.noClassLabel.isHidden = false
        }
    }
    
    func sortClasses() {
        var openClasses: [Course] = []
        var fullClasses: [Course] = []
        var waitlClasses: [Course] = []
        var newOnlyClasses: [Course] = []
        
        // separate class by status
        for course in courses {
            if course.status == Status.OPEN { openClasses.append(course) }
            else if course.status == Status.FULL { fullClasses.append(course) }
            else if course.status == Status.Waitl { waitlClasses.append(course) }
            else { newOnlyClasses.append(course) }
        }
        
        // sort classes
        openClasses = openClasses.sorted(by: { $0.course_name < $1.course_name })
        fullClasses = fullClasses.sorted(by: { $0.course_name < $1.course_name })
        waitlClasses = waitlClasses.sorted(by: { $0.course_name < $1.course_name })
        newOnlyClasses = newOnlyClasses.sorted(by: { $0.course_name < $1.course_name })
        
        // join together
        courses = openClasses + waitlClasses + newOnlyClasses + fullClasses
    }
    
    func setUpAddLabel() {
        guard let window = UIApplication.shared.keyWindow else { return }
        
        noClassLabel = UILabel(frame: CGRect(x: 0, y: 0, width: 250, height: 350))
        noClassLabel.font = UIFont(name: "Futura", size: 20.0)
        noClassLabel.center = window.center
        noClassLabel.textAlignment = .center
        noClassLabel.text = "You aren't tracking any classes yet. Click below to get started!"
        noClassLabel.numberOfLines = 3
        
        noClassLabel.center = self.view.center
        noClassLabel.center.x = self.view.center.x
        noClassLabel.center.y = self.view.center.y
        
        labelHasBeenPresented = true
        
        self.view.addSubview(noClassLabel)
    }
    
    func handleReferral() {
        // this device was never referred at any point
        if !UserDefaults.standard.bool(forKey: Defaults.wasReferred) { return }
        // if referral was used alraedy, return
        if UserDefaults.standard.bool(forKey: Defaults.hasUsedOneReferral) { print("referral used"); return }
        
        // referralEmail = the person who referred you
        guard let referralEmail = UserDefaults.standard.string(forKey: Defaults.referralEmail) else {
            print("Couldn't find referral email in sign up")
            return
        }
        
        // get the document of the referrer
        let db = Firestore.firestore()
        let docRef = db.collection(DataBase.User).document(referralEmail)
        docRef.getDocument { (document, error) in
            if let error = error {
                print("Error getting document for referral", error.localizedDescription)
                return
            }
            let data = document?.data()
            
            guard let num_referrals = data?[DataBase.num_referrals] as? Int else {
                print("Couldnt find num referrals")
                return
            }
            // This device will not be able to send anyone else a referral link
            UserDefaults.standard.set(true, forKey: Defaults.hasUsedOneReferral)
            docRef.updateData([DataBase.num_referrals: num_referrals + 1 ])
            Stats.logSignedUpFromReferral()
            print("Num referrals updated successfully ")
        }
    }
    
    func slideInMenu() {
        guard let menuVC = storyboard?.instantiateViewController(identifier: "MenuController") as? MenuController else { return }
        menuVC.didTapMenuType = { menuType in
            let menuTypeString = String(describing: menuType)
            
            switch menuTypeString {
                
            case "Notifications":
                self.presentNotifications()
                
            case "Settings":
                self.presentSettings()
                
            case "Premium":
                self.presentStore()
                
            case "HowItWorks":
                self.presentHowItWorks()
                
            case "Share":
                self.presentShareController()
                
            case "Support":
                self.presentEmailSupport()
                
            case "WhatsNew":
                self.presentWhatsNew()
                
            case "Credits":
                self.presentCredits()
                
            case "Updates":
                self.presentWhatsNew()
                
            default:
                return
            }
        }
        menuVC.modalPresentationStyle = .overCurrentContext
        menuVC.transitioningDelegate = self
        present(menuVC, animated: true, completion: nil)
    }
    
    @objc func refreshTableView() {
        let dispatchGroup = DispatchGroup()
        ServerService.getClassStatus(withGroup:dispatchGroup, homeVC: self)
        
        dispatchGroup.notify(queue: .main) {
            self.refreshControl?.endRefreshing()
            self.sortClasses()
            self.tableView.reloadData()
            self.toggleNoClassLabel()
        }
    }
    
    @objc func didSwipeOnView(gestureRecognizer: UIPanGestureRecognizer) {
        // Swiping from left to right
        if case .Right = gestureRecognizer.horizontalDirection(target: self.view)  {
            slideInMenu()
        }
    }
    
    @IBAction func addClassClicked(_ sender: Any) {        
        if !emailIsVerified() { presentVerificationSentAlert();  return }
        if UserService.user.hasPremium || UserService.user.courseCodes.count <  1{
            presentAddClassesController()
            handleReferral()
            return
        }
        
        presentStore()
    }
    
    @IBAction func menuClicked(_ sender: Any) {
        slideInMenu()
    }
}


extension HomePageController:  UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.courses.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let row = indexPath.row
        let cell = tableView.dequeueReusableCell(withIdentifier: "TrackedCell") as! TrackedCell
        let course = courses[row]
        
        cell.courseCodeLabel.text = "\(course.course_name) \(course.course_type) \(course.section)"
        cell.statusLabel.text = self.courses[row].status
        cell.cellView.layer.cornerRadius = 5
        updateUI(withCell: cell, withResponce: self.courses[row].status)
        return cell
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            self.removeClass(atIndexPath: indexPath)
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        //        presentClassDetailC	ontroller(course: courses[indexPath.row], indexPath: indexPath)
        presentClassDetailsController(course: courses[indexPath.row], indexPath: indexPath)
    }
    
    func didTapOpenOrWaitlist() -> Bool {
        return true
    }
    
    func updateUI(withCell cell: TrackedCell, withResponce response: String) {
        switch response {
        case Status.OPEN:
            cell.cellView.backgroundColor = #colorLiteral(red: 0.4574845033, green: 0.8277172047, blue: 0.4232197912, alpha: 0.2520467252)
            return
        case Status.Waitl:
            cell.cellView.backgroundColor = #colorLiteral(red: 0.8425695398, green: 0.8208485929, blue: 0, alpha: 0.248053115)
            return
        case Status.FULL:
            cell.cellView.backgroundColor = #colorLiteral(red: 0.8103429773, green: 0.08139390926, blue: 0.116439778, alpha: 0.2456195088)
            return
        case Status.NewOnly:
            cell.cellView.backgroundColor = #colorLiteral(red: 0, green: 0.6157837616, blue: 0.9281850962, alpha: 0.2466803115)
            return
        default:
            cell.cellView.backgroundColor = #colorLiteral(red: 0.505957987, green: 0.01517132679, blue: 0.8248519059, alpha: 0.2461187101)
            return
        }
    }
}

extension HomePageController: UIViewControllerTransitioningDelegate {
    func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        transition.isPresenting = true
        print(transition.isPresenting)
        return transition
    }
    
    func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        transition.isPresenting = false
        print(transition.isPresenting)
        return transition
    }
}

extension HomePageController: MFMailComposeViewControllerDelegate {
    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        
        if error != nil {
            controller.displaySimpleError(title: "Could Not Send Email", message: "Could not send you email. You can also send an email to \(AppConstants.support_email).", completion: {_ in
                controller.dismiss(animated: true, completion: nil)
            })
            return
        }
        
        switch result{
        case .cancelled:
            controller.dismiss(animated: true, completion: nil)
        case .saved:
            print("saved")
            controller.displaySimpleError(title: "Email Saved", message: "Your email has been saved to your drafts.", completion: {_ in
                controller.dismiss(animated: true, completion: nil)
            })
        case .sent:
            controller.displaySimpleError(title: "Email Sent", message: "Your email has sent successfully!", completion: {_ in
                controller.dismiss(animated: true, completion: nil)
            })
            print("sent")
        case .failed:
            controller.displaySimpleError(title: "Error Sending Email", message: "Could not send you email. You can also send an email to \(AppConstants.support_email)", completion: {_ in
                controller.dismiss(animated: true, completion: nil)
            })
            print("failed")
        @unknown default:
            controller.dismiss(animated: true, completion: nil)
            print("unkown")
        }
    }
}

