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
    var stripeId: String
    var firstName: String
    var lastName: String
    
    var school: String
    var fcm_token: String
    var purchaseHistory: [ [String: String] ] // [ [course_code: '34250', date: Date] ]
    var receiveEmails: Bool
    var notifications: [ [String: String] ] // [ [course_code: '34250', status: 'FULL OPEN', data: Date] ]?
    
    var classes: [String: [Any]]
    var classArr: [String] { return Array(classes.keys) }
    var fullName: String { return "\(firstName) \(lastName)" }
    
    
    // User is Signing Up
    init(id: String = "", email: String = "", firstName: String = "",
         lastName: String = "", stripeId: String = "", webReg: Bool = false,
         webRegPswd: String = "", classes: [String: [Any]] = [:], school: String = "",
         fcm_token: String = "", purchaseHistory: [[String: String]] = [],
         receiveEmails: Bool = true, notifications: [[String: String]] = [] ){
        
        self.id = id
        self.email = email
        self.stripeId = stripeId
        self.firstName = firstName
        self.lastName = lastName
        self.webReg = webReg
        self.webRegPswd = webRegPswd
        self.classes = classes
        
        self.school = school
        self.fcm_token = fcm_token
        self.purchaseHistory = purchaseHistory
        self.receiveEmails = receiveEmails
        self.notifications = notifications
        
        setFCMToken()
        print("user is made ''")
    }
    
    // User is Logging In
    init(data: [String: Any]) {
        self.id = data["id"] as? String ?? ""
        self.email = data["email"] as? String ?? ""
        self.stripeId = data["stripeId"] as? String ?? ""
        self.firstName = data["first_name"] as? String ?? ""
        self.lastName = data["last_name"] as? String ?? ""
        self.webReg = data["web_reg"] as? Bool ?? false
        self.webRegPswd = data["web_reg_pswd"] as? String ?? ""
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
            
            "school": user.school,
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
