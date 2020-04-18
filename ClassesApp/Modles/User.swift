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
    var freeClasses: Int
    var receiveEmails: Bool
    var classes: [String: [Any]]
    var purchaseHistory: [ [String: String] ] // [ [course_code: '34250', date: Date, price: 149] ]
    var notifications: [ [String: String] ] // [ [course_code: '34250', status: 'FULL OPEN', date: Date] ]?
    
    var revNotifications: [ [String: String] ] { return notifications.reversed()}
    var revPurchaseHistory: [ [String: String] ] { return purchaseHistory.reversed()}
    var classArr: [String] { return Array(classes.keys) }
    var fullName: String { return "\(firstName) \(lastName)" }
    
    
    // User is Signing Up
    init(id: String = "", email: String = "", firstName: String = "",
         lastName: String = "", webReg: Bool = false, webRegPswd: String = "",
         stripeId: String = "", classes: [String: [Any]] = [:], school: String = "",
         fcm_token: String = "", freeClasses: Int = 0, credits: Int = 0, receiveEmails: Bool = true,
         isLoggedIn: Bool = true, purchaseHistory: [[String: String]] = [],
         notifications: [[String: String]] = [] ){
        
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
        self.credits = credits
        self.freeClasses = freeClasses
        self.classes = classes
        self.purchaseHistory = purchaseHistory
        self.notifications = notifications
        
        setFCMToken()
        print("user is made ''")
    }
    
    // User is Logging In
    init(data: [String: Any]) {
        self.id = data["id"] as? String ?? ""
        self.email = data["email"] as? String ?? "-.-"
        self.stripeId = data["stripeId"] as? String ?? ""
        self.firstName = data["first_name"] as? String ?? ""
        self.lastName = data["last_name"] as? String ?? ""
        self.webReg = data["web_reg"] as? Bool ?? false
        self.webRegPswd = data["web_reg_pswd"] as? String ?? ""
        self.credits = data["credits"] as? Int ?? 0
        self.freeClasses = data["free_classes"] as? Int ?? 0
        self.isLoggedIn = data["is_logged_in"] as? Bool ?? true
        if let classes = data["classes"] as? [String : [Any]] {
            print("Cast successful")
            self.classes = classes
        }
        else {
            print("Cast unsuccessful")
            self.classes = [:]
        }
        
        
        self.school = data["school"] as? String ?? ""
        self.fcm_token = data["fcm_token"] as? String ?? ""
        self.receiveEmails = data["receive_emails"] as? Bool ?? true
        
        if let purchaseHistory =  data["purchase_history"] as? [[String : String]] {
            self.purchaseHistory = purchaseHistory
        } else { self.purchaseHistory = [] }
        
        if let notifications =  data["notifications"] as? [[String : String]] {
            self.notifications = notifications
        } else { self.notifications = [] }
        
        
        setFCMToken()
        print("user is made")
    }
    
    // Sending user data to Firebase
    static func modelToData(user: User) -> [String: Any] {
        let data : [String: Any] = [
            "id" : user.id,
            "email" : user.email,
            "stripeId": user.stripeId,
            "first_name": user.firstName,
            "last_name": user.lastName,
            "web_reg": user.webReg,
            "web_reg_pswd": user.webRegPswd,
            
            "classes": user.classes,
            "is_logged_in": user.isLoggedIn,
            "free_classes": user.freeClasses,
            "school": user.school,
            "credits": user.credits,
            "fcm_token": user.fcm_token,
            "purchase_history": user.purchaseHistory,
            "receive_emails": user.receiveEmails,
            "notifications": user.notifications,
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
        db.collection("User").document(self.email).setData(["fcm_token": new_fcm,], merge: true) { err in
            if let err = err {
                print("COULD NOT UPDATE FCM TOKEN: \(err.localizedDescription)")
            }
            else {
                print("Customer fcm Token was updated!")
            }
        }
    }
}
