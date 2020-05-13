//
//  User.swift
//  ClassesApp
//
//  Created by Darrel Muonekwu on 3/25/20.
//  Copyright © 2020 Darrel Muonekwu. All rights reserved.
//

import Foundation
import FirebaseAuth
import FirebaseFirestore
import FirebaseMessaging


class User {
    var id: String
    
    var email: String
    var school: String
    var stripeId: String
    var fcm_token: String
    var webRegPswd: String
    var referralLink: String
    
    var webReg: Bool
    var isLoggedIn:Bool
    var hasPremium: Bool
    var receiveEmails: Bool
    var isEmailVerified: Bool
    var seenWelcomePage: Bool
    var hasShortReferral: Bool
    var notificationsEnabled: Bool
    
    var hasSetUserProperty: Bool
    
    var seenHomeTapDirections: Bool
    
    var numReferrals: Int

    var classes: [String: [Any]]
    
    var purchaseHistory: [[String: String]] // [ [num_credits: 3, date: Date, price: 149] ]
    var notifications: [[String: String]] // [ [course_code: '34250', status: 'FULL OPEN', date: Date] ]?
    
    var revNotifications: [ [String: String] ] { return notifications.reversed()}
    var revPurchaseHistory: [ [String: String] ] { return purchaseHistory.reversed()}
    var courseCodes: [String] { return Array(classes.keys) }
    
    // User is Signing Up
    init(id: String = "", email: String = "", webReg: Bool = false, webRegPswd: String = "",
         stripeId: String = "", classes: [String: [Any]] = [:], school: String = "",
         hasShortReferral: Bool  = false, fcm_token: String = "", numReferrals: Int = 0,
         hasPremium: Bool = false, receiveEmails: Bool = true, seenWelcomePage: Bool = false,
         isLoggedIn: Bool = true, isEmailVerified: Bool = false, referralLink: String = "",
         seenHomeTapDirections: Bool = false, hasSetUserProperty: Bool = false,
         notificationsEnabled: Bool = true, purchaseHistory: [[String: String]] = [],
         notifications: [[String: String]] = []){
        
        self.id = id
        self.email = email
        self.webReg = webReg
        self.webRegPswd = webRegPswd
        self.stripeId = stripeId
        
        self.hasPremium = hasPremium
        self.hasShortReferral = hasShortReferral
        self.referralLink = referralLink
        self.numReferrals = numReferrals
        self.isLoggedIn = isLoggedIn
        self.school = school
        self.fcm_token = fcm_token
        self.receiveEmails = receiveEmails
        self.isEmailVerified = isEmailVerified
        self.seenWelcomePage = seenWelcomePage
        self.classes = classes
        self.purchaseHistory = purchaseHistory
        self.notificationsEnabled = notificationsEnabled
        self.notifications = notifications
        
        self.hasSetUserProperty = hasSetUserProperty
        
        self.seenHomeTapDirections = seenHomeTapDirections
        
        setFCMTokenAndUpdateDB()
        print("user is made")
    }
    
    // User is Logging In
    init(data: [String: Any]) {
        self.id = data[DataBase.id] as? String ?? ""
        self.email = data[DataBase.email] as? String ?? ""
        self.stripeId = data[DataBase.stripeId] as? String ?? ""
        self.webReg = data[DataBase.web_reg] as? Bool ?? false
        self.webRegPswd = data[DataBase.web_reg_pswd] as? String ?? ""
        self.hasShortReferral = data[DataBase.has_short_referral] as? Bool ?? false
        self.numReferrals = data[DataBase.num_referrals] as? Int ?? 0
        self.referralLink = data[DataBase.referral_link] as? String ?? ""
        self.hasPremium = data[DataBase.has_premium] as? Bool ?? false
        self.isLoggedIn = data[DataBase.is_logged_in] as? Bool ?? true
        if let classes = data[DataBase.classes] as? [String : [Any]] {
            print("Cast successful")
            self.classes = classes
        }
        else {
            print("Cast unsuccessful")
            self.classes = [:]
        }
        
        self.hasSetUserProperty = data[DataBase.has_set_user_poperty] as? Bool ?? false
        
        self.school = data[DataBase.school] as? String ?? ""
        self.fcm_token = data[DataBase.fcm_token] as? String ?? ""
        self.receiveEmails = data[DataBase.receive_emails] as? Bool ?? true
        self.isEmailVerified = data[DataBase.is_email_verified] as? Bool ?? false
        self.seenWelcomePage = data[DataBase.seen_welcome_page] as? Bool ?? false
        self.notificationsEnabled = data[DataBase.notifications_enabled] as? Bool ?? true
        
        if let purchaseHistory =  data[DataBase.purchase_history] as? [[String : String]] {
            self.purchaseHistory = purchaseHistory
        } else { self.purchaseHistory = [] }
        
        if let notifications =  data[DataBase.notifications] as? [[String : String]] {
            self.notifications = notifications
        } else { self.notifications = [] }
        
        
        self.seenHomeTapDirections = data[DataBase.seen_home_tap_directions] as? Bool ?? false
        
        setFCMTokenAndUpdateDB()
        print("user is made")
    }
    
    // Sending user data to Firebase
    static func modelToData(user: User) -> [String: Any] {
        let data : [String: Any] = [
            DataBase.id : user.id,
            DataBase.email : user.email,
            DataBase.stripeId: user.stripeId,
            DataBase.web_reg: user.webReg,
            DataBase.web_reg_pswd: user.webRegPswd,
            
            DataBase.classes: user.classes,
            DataBase.has_premium: user.hasPremium,
            DataBase.is_logged_in: user.isLoggedIn,
            DataBase.school: user.school,
            DataBase.fcm_token: user.fcm_token,
            DataBase.purchase_history: user.purchaseHistory,
            DataBase.receive_emails: user.receiveEmails,
            DataBase.is_email_verified: user.isEmailVerified,
            DataBase.seen_welcome_page: user.seenWelcomePage,
            DataBase.notifications: user.notifications,
            DataBase.num_referrals: user.numReferrals,
            DataBase.referral_link: user.referralLink,
            DataBase.has_short_referral: user.hasShortReferral,
            DataBase.notifications_enabled: user.notificationsEnabled,
            DataBase.seen_home_tap_directions: user.seenHomeTapDirections,
            DataBase.has_set_user_poperty:user.hasSetUserProperty
        ]
        
        return data
    }
    
    private func handleEmailVerification() {
        // If email is not verified
        if isEmailVerified { return }
        guard let user = Auth.auth().currentUser else { return }
        if user.isEmailVerified {
            isEmailVerified = true
            
            let db = Firestore.firestore()
            let docRef = db.collection(DataBase.User).document(UserService.user.email)
            docRef.updateData([DataBase.is_email_verified: true])
            return
        }
    }
    
    private func setFCMTokenAndUpdateDB() {
        if UserService.fcm_token_has_set  { print("fcm_token_has_set = \(UserService.fcm_token_has_set) "); return }
        
        print("fcm_token_has_set = \(UserService.fcm_token_has_set) ")
        UserService.fcm_token_has_set = true
        
        let new_fcm = Messaging.messaging().fcmToken ?? "couldnt get fcm token"
        if new_fcm == self.fcm_token { print("fcm Token is the same as last login!"); return }
        
        let db = Firestore.firestore()
        db.collection(DataBase.User).document(self.email).setData([DataBase.fcm_token: new_fcm, DataBase.is_logged_in: true], merge: true) { err in
            if let err = err {
                print("COULD NOT UPDATE FCM TOKEN: \(err.localizedDescription)")
            }
            else {
                print("Customer fcm Token was updated!")
            }
        }
        
    }
}
