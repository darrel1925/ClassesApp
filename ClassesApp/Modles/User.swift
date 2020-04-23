//
//  User.swift
//  ClassesApp
//
//  Created by Darrel Muonekwu on 3/25/20.
//  Copyright © 2020 Darrel Muonekwu. All rights reserved.
//

import Foundation
import FirebaseFirestore
import FirebaseMessaging


class User {
    
    var id: String
    var email: String
    var webReg: Bool
    var webRegPswd: String
    var firstName: String
    var lastName: String
    var stripeId: String
    var isLoggedIn:Bool
    
    var school: String
    var fcm_token: String
    var credits: Int
    var receiveEmails: Bool
    var seenWelcomePage: Bool
    var classes: [String: [Any]]
    var trackedClasses: [String]
    var purchaseHistory: [ [String: String] ] // [ [num_credits: 3, date: Date, price: 149] ]
    var notifications: [ [String: String] ] // [ [course_code: '34250', status: 'FULL OPEN', date: Date] ]?
    
    var revNotifications: [ [String: String] ] { return notifications.reversed()}
    var revPurchaseHistory: [ [String: String] ] { return purchaseHistory.reversed()}
    var classArr: [String] { return Array(classes.keys) }
    var fullName: String { return "\(firstName) \(lastName)" }
    
    
    // User is Signing Up
    init(id: String = "", email: String = "", firstName: String = "",
         lastName: String = "", webReg: Bool = false, webRegPswd: String = "",
         stripeId: String = "", classes: [String: [Any]] = [:], school: String = "",
         fcm_token: String = "", credits: Int = 0, receiveEmails: Bool = true,
         seenWelcomePage: Bool = false, isLoggedIn: Bool = true,
         purchaseHistory: [[String: String]] = [], notifications: [[String: String]] = [],
         trackedClasses: [String] = []){
        
        self.id = id
        self.email = email
        self.webReg = webReg
        self.webRegPswd = webRegPswd
        self.firstName = firstName
        self.lastName = lastName
        self.stripeId = stripeId
        
        self.isLoggedIn = isLoggedIn
        self.school = school
        self.fcm_token = fcm_token
        self.receiveEmails = receiveEmails
        self.seenWelcomePage = seenWelcomePage
        self.credits = credits
        self.classes = classes
        self.purchaseHistory = purchaseHistory
        self.notifications = notifications
        self.trackedClasses = trackedClasses
        
        setFCMToken()
        print("user is made ''")
    }
    
    // User is Logging In
    init(data: [String: Any]) {
        self.id = data[DataBase.id] as? String ?? ""
        self.email = data[DataBase.email] as? String ?? "-.-"
        self.stripeId = data[DataBase.stripeId] as? String ?? ""
        self.firstName = data[DataBase.first_name] as? String ?? ""
        self.lastName = data[DataBase.last_name] as? String ?? ""
        self.webReg = data[DataBase.web_reg] as? Bool ?? false
        self.webRegPswd = data[DataBase.web_reg_pswd] as? String ?? ""
        self.credits = data[DataBase.credits] as? Int ?? 0
        self.isLoggedIn = data[DataBase.is_logged_in] as? Bool ?? true
        if let classes = data[DataBase.classes] as? [String : [Any]] {
            print("Cast successful")
            self.classes = classes
        }
        else {
            print("Cast unsuccessful")
            self.classes = [:]
        }
        
        
        self.school = data[DataBase.school] as? String ?? ""
        self.fcm_token = data[DataBase.fcm_token] as? String ?? ""
        self.receiveEmails = data[DataBase.receive_emails] as? Bool ?? true
        self.seenWelcomePage = data[DataBase.seen_welcome_page] as? Bool ?? false
        self.trackedClasses = data[DataBase.tracked_classes] as? [String] ?? []
        if let purchaseHistory =  data[DataBase.purchase_history] as? [[String : String]] {
            self.purchaseHistory = purchaseHistory
        } else { self.purchaseHistory = [] }
        
        if let notifications =  data[DataBase.notifications] as? [[String : String]] {
            self.notifications = notifications
        } else { self.notifications = [] }
        
        
        setFCMToken()
        print("user is made")
    }
    
    // Sending user data to Firebase
    static func modelToData(user: User) -> [String: Any] {
        let data : [String: Any] = [
            DataBase.id : user.id,
            DataBase.email : user.email,
            DataBase.stripeId: user.stripeId,
            DataBase.first_name: user.firstName,
            DataBase.last_name: user.lastName,
            DataBase.web_reg: user.webReg,
            DataBase.web_reg_pswd: user.webRegPswd,
            
            DataBase.classes: user.classes,
            DataBase.is_logged_in: user.isLoggedIn,
            DataBase.school: user.school,
            DataBase.credits: user.credits,
            DataBase.fcm_token: user.fcm_token,
            DataBase.purchase_history: user.purchaseHistory,
            DataBase.receive_emails: user.receiveEmails,
            DataBase.seen_welcome_page: user.seenWelcomePage,
            DataBase.notifications: user.notifications,
            DataBase.tracked_classes: user.trackedClasses
        ]
        
        return data
    }
    
    private func setFCMToken() {
        if UserService.isLoggedIn == true { print("\nreturning loggedin = \(UserService.isLoggedIn) "); return }
        
        print("\nreturning loggedin = \(UserService.isLoggedIn) ")
        UserService.isLoggedIn = true
        let new_fcm = Messaging.messaging().fcmToken ?? "couldnt get fcm token"
        if new_fcm == self.fcm_token && self.fcm_token != "" { print("fcm Token is the same as last login!"); return }

        let db = Firestore.firestore()
        db.collection(DataBase.User).document(self.email).setData([DataBase.fcm_token: new_fcm,], merge: true) { err in
            if let err = err {
                print("COULD NOT UPDATE FCM TOKEN: \(err.localizedDescription)")
            }
            else {
                print("Customer fcm Token was updated!")
            }
        }
    }
}
