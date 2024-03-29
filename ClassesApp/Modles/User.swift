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
    var appVersion: String
    var dateJoined: String
    var webRegPswd: String
    var referralLink: String
    
    var webReg: Bool
    var isLoggedIn: Bool
    var hasPremium: Bool
    var hasAutoEnroll: Bool
    var receiveEmails: Bool
    var isEmailVerified: Bool
    var seenWelcomePage: Bool
    var hasShortReferral: Bool
    var notificationsEnabled: Bool
        
    var seenHomeTapDirections: Bool
    var seenWhatsNew: Bool
    
    var promptUpdateCount: Int // unused
    var numReferrals: Int
    var badgeCount: Int

    var classes: [String: Any]
    
    var purchaseHistory: [[String: String]] // [ [num_credits: 3, date: Date, price: 149] ]
    var notifications: [[String: String]]
    
    var revNotifications: [ [String: String] ] { return notifications.reversed()}
    var revPurchaseHistory: [ [String: String] ] { return purchaseHistory.reversed()}
    var courseCodes: [String] { return Array(classes.keys) }
    var authenticated: Bool { return AppConstants.authenticated }
    var hasConfirmedEmail: Bool { return AppConstants.has_confirmed_email }
    
    // User is Signing Up
    init(id: String = "", email: String = "", webReg: Bool = false, webRegPswd: String = "",
         stripeId: String = "", classes: [String: Any] = [:], school: String = "", dateJoined: String = "",
         hasShortReferral: Bool  = false, fcm_token: String = "", numReferrals: Int = 0, badgeCount: Int = 0,
         promptUpdateCount: Int = 0, hasPremium: Bool = false, receiveEmails: Bool = false,
         seenWelcomePage: Bool = false, isLoggedIn: Bool = true, isEmailVerified: Bool = false,
         referralLink: String = "", hasAutoEnroll: Bool = false, appVersion: String = "",
         seenHomeTapDirections: Bool = false, hasSetUserProperty: Bool = false,
         seenWhatsNew: Bool = false, notificationsEnabled: Bool = true,
         purchaseHistory: [[String: String]] = [], notifications: [[String: String]] = []) {
        
        self.id = id
        self.email = email
        self.webReg = webReg
        self.webRegPswd = webRegPswd
        self.stripeId = stripeId
        
        self.badgeCount = badgeCount
        self.promptUpdateCount = promptUpdateCount
        self.dateJoined = dateJoined
        self.appVersion = appVersion
        self.hasPremium = hasPremium
        self.hasAutoEnroll = hasAutoEnroll
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
                
        self.seenHomeTapDirections = seenHomeTapDirections
        self.seenWhatsNew = seenWhatsNew
        
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
        self.hasAutoEnroll = data[DataBase.has_auto_enroll] as? Bool ?? false
        self.isLoggedIn = data[DataBase.is_logged_in] as? Bool ?? true
        if let classes = data[DataBase.classes] as? [String : Any] {
            print("Class cast successful")
            self.classes = classes
        }
        else {
            print("Class cast unsuccessful")
            self.classes = [:]
        }
        self.promptUpdateCount = data[DataBase.prompt_update_count] as? Int ?? 0
        self.badgeCount = data[DataBase.badge_count] as? Int ?? 0
        self.school = data[DataBase.school] as? String ?? ""
        self.dateJoined = data[DataBase.date_joined] as? String ?? ""
        self.appVersion = data[DataBase.app_version] as? String ?? ""
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
        self.seenWhatsNew = data[DataBase.seen_whats_new] as? Bool ?? false
        
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
            
            DataBase.prompt_update_count: user.promptUpdateCount,
            DataBase.badge_count: 0,
            DataBase.date_joined: user.dateJoined,
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
            DataBase.has_auto_enroll: user.hasAutoEnroll,
            DataBase.has_short_referral: user.hasShortReferral,
            DataBase.notifications_enabled: user.notificationsEnabled,
            DataBase.seen_home_tap_directions: user.seenHomeTapDirections,
            DataBase.seen_whats_new: user.seenWhatsNew,
            DataBase.app_version: user.appVersion,
        ]
        return data
    }
    
//    private func setFCMTokenAndUpdateDB() {
//        if UserService.fcm_token_has_set { print("fcm_token_has_set = \(UserService.fcm_token_has_set) "); return }
//        
//        print("fcm_token_has_set = \(UserService.fcm_token_has_set) ")
//        UserService.fcm_token_has_set = true
//        
//        let new_fcm = Messaging.messaging().fcmToken ?? "couldnt get fcm token"
//        if new_fcm == self.fcm_token { print("fcm Token is the same as last login!"); return }
//        
//        let db = Firestore.firestore()
//        db.collection(DataBase.User).document(self.email).setData([DataBase.fcm_token: new_fcm, DataBase.is_logged_in: true], merge: true) { err in
//            if let err = err {
//                print("COULD NOT UPDATE FCM TOKEN: \(err.localizedDescription)")
//            }
//            else {
//                print("Customer fcm Token was updated!")
//            }
//        }
//    }
}
