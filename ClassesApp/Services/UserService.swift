//
//  UserService.swift
//  ClassesApp
//
//  Created by Darrel Muonekwu on 3/26/20.
//  Copyright © 2020 Darrel Muonekwu. All rights reserved.
//

import Foundation
import Firebase
import FirebaseAuth
import FirebaseFirestore

let UserService = _UserService()

final class _UserService {
    var user: User!
    var userListener: ListenerRegistration? = nil // our listener
    var fcm_token_has_set: Bool = false
    
    func getCurrentUser(email: String,  completion: @escaping () -> ()) {
        // if user is logged in
        let db = Firestore.firestore()
        let userRef = db.collection(DataBase.User).document(email)
        userRef.updateData([DataBase.is_logged_in : true])
        // if user changes something in document, it will always be up to date in our app
        userListener = userRef.addSnapshotListener({ (snap, error) in
            
            if let error = error {
                print("could not add snapShotListener :/")
                debugPrint(error.localizedDescription)
                completion()
            }
            
//             if we can get user infor from db
            guard let data = snap?.data() else {
                print("no data")
                completion()
                return
            }
            // add it to out user so we can access it globally
//            print("Data is \(data)")
            self.user = User.init(data: data)
            print("user info has been updated")
            self.updateDbWithNewInfo()
            completion()
        })
    }
    
    func updateDbWithNewInfo() {
        print("updateWithNewInfo")
        if self.user == nil || self.user.email == "" { return } // in the off chance the user is logged in but doesnt have an account, bc it was deleted (should never happen)

        print("updateFirebaseWithUpdatedVars")
        UserService.updateFirebaseWithUpdatedVars()
    }
        
    func updateFirebaseWithUpdatedVars() {
        let db = Firestore.firestore()
        let docRef = db.collection(DataBase.User).document(user.email)
        let userInfo = User.modelToData(user: user)
        docRef.setData(userInfo, merge: true)
        print("user info merged")
    }
    
    func checkForShortLink() {
        if user.hasShortReferral { return }
        print("User does not have short link")
        generateReferralLink()
    }
    
    
    func setFCM() {
        if user.fcm_token ==  Messaging.messaging().fcmToken { print("fcm is good"); return }
        
        let new_fcm = Messaging.messaging().fcmToken ?? "couldnt get fcm token"
        
        let db = Firestore.firestore()
        db.collection(DataBase.User).document(user.email).setData([DataBase.fcm_token: new_fcm], merge: true) { err in
            if let err = err {
                print("COULD NOT UPDATE FCM TOKEN: \(err.localizedDescription)")
            }
            else {
                print("Customer fcm Token was updated!")
            }
        }
    }
    
    func resetBadgeCount() {
        if user.badgeCount == 0 { return }
        
        let db = Firestore.firestore()
        db.collection(DataBase.User).document(user.email).setData([DataBase.badge_count: 0], merge: true) { err in
            if let err = err {
                print("COULD NOT UPDATE BADGE COUNT: \(err.localizedDescription)")
            }
        }
    }
    
    func setAppVersion() {
        ServerService.getCurrentAppVersion { (version, success) in
            if !success { return }
            
            if UserService.user.appVersion != version {
                let db = Firestore.firestore()
                let docRef = db.collection(DataBase.User).document(UserService.user.email)
                docRef.updateData([DataBase.app_version: version])
            }
        }
    }
    
    func setDateJoined() {
        if user.dateJoined != "" { return }
        
        let db = Firestore.firestore()
        db.collection(DataBase.User).document(user.email).setData([DataBase.date_joined: Date().toString()], merge: true) { err in
            if let err = err {
                print("COULD NOT UPDATE DATE JOINED: \(err.localizedDescription)")
            }
        }
    }
    
    func generateReferralLink() {
        // Create url that will get parsed and give you the parameters
        print(ReferralLink.scheme)
        print(ReferralLink.host)
        print(ReferralLink.path)
        
        var components = URLComponents()
        components.scheme = ReferralLink.scheme
        components.host = ReferralLink.host // should be appstore link
        components.path = ReferralLink.path
        
        print("components.path")
        let userInfoQueryItem = URLQueryItem(name: "email", value: UserService.user.email)
        components.queryItems = [userInfoQueryItem]
        
        // Full url with all parameters included
        guard let linkParameter = components.url else { return }
        print("let linkParameter",  linkParameter.absoluteString)
        // Create the big dynamic link
        guard let shareLink = DynamicLinkComponents.init(link: linkParameter, domainURIPrefix: ReferralLink.domainURIPrefix ) else { return }
        
        if let bundleId = Bundle.main.bundleIdentifier {
            shareLink.iOSParameters = DynamicLinkIOSParameters(bundleID: bundleId)
        }
        
        // Where to direct users if app is not installed
        shareLink.iOSParameters?.appStoreID = ReferralLink.appStoreID // <-- Google phots adding comment =
        
        // Used to present how link is displayed and to populate inbetween screen before app store
        shareLink.socialMetaTagParameters = DynamicLinkSocialMetaTagParameters()
        shareLink.socialMetaTagParameters?.title = ReferralLink.metaTagTitle
        shareLink.socialMetaTagParameters?.descriptionText = ReferralLink.metaTagDescription
        
        if let imageURL = URL(string: ReferralLink.imageURL ) {
            shareLink.socialMetaTagParameters?.imageURL = imageURL
        }
        
        guard let longURL = shareLink.url else { return }
        print("Long dynamic URL is \(longURL.absoluteString)")
        
        
        shareLink.shorten { (url, warnings, error) in
            if let error = error {
                print("Got error shortening the link! \(error.localizedDescription)")
            }
            
            if let warnings = warnings {
                for warning in warnings {
                    print("DYNAMIC LINK WARNING \(warning)")
                }
            }
            
            guard let shortURL = url else { return }
            print("Short dynamic URL is \(shortURL)")
            
            let stringShortUrl = "\(shortURL)"
            let db = Firestore.firestore()
            let userRef = db.collection(DataBase.User).document(self.user.email)
            userRef.updateData([DataBase.referral_link : stringShortUrl, DataBase.has_short_referral: true])
            
            return
        }
        
        // use long url instead
        let stringLongURL = "\(longURL)"
        let db = Firestore.firestore()
        let userRef = db.collection(DataBase.User).document(user.email)
        userRef.updateData([DataBase.referral_link : stringLongURL])
        
        
    }
    
    func setIsLoggedIn(email: String, completion: @escaping () -> ()) {
        print(user.email)
        let db = Firestore.firestore()
        let userRef = db.collection(DataBase.User).document(email)
        userRef.setData([DataBase.is_logged_in : false], merge: true) { (err) in
            print("entered set is_logged_in for logout function")
            if let _ = err {
                print("Error setting is_logged_in ERROR")
                
            }
            else {
                print("is_logged_in_set SET")
            }
            completion()
        }
    }
    
    func logoutUser() {
        print("trying")
        self.userListener?.remove()
        self.userListener = nil
        self.user = nil
        self.fcm_token_has_set = false
    }
}
