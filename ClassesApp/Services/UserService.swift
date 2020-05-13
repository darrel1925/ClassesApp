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
    var isLoggedIn: Bool = false // <-- to handle updating fcm token in User when same account logged in on two diff devices

    var user: User!
    var userListener: ListenerRegistration? = nil // our listener
    var fcm_token_has_set: Bool = false
    let dispatchGroup = DispatchGroup()
    let db = Firestore.firestore()
    
    func getCurrentUser(email: String) {
        // if user is logged in

        let userRef = db.collection(DataBase.User).document(email)
        userRef.updateData([DataBase.is_logged_in : true])
        // if user changes something in document, it will always be up to date in our app
        userListener = userRef.addSnapshotListener({ (snap, error) in

            if let error = error {
                print("could not add snapShotListener :/")
                debugPrint(error.localizedDescription)
                return
            }
            
            // if we can get user infor from db
            guard let data = snap?.data() else { return }
            // add it to out user so we can access it globally
//            print("Data is \(data)")
            self.user = User.init(data: data)
            print("user info has been updated")
            self.dispatchGroup.customLeave()
        })
        
        dispatchGroup.notify(queue: .main) {
            print("updateFirebaseWithUpdatedVars")
            UserService.updateFirebaseWithUpdatedVars()
            print("checkForShortLink")
            UserService.checkForShortLink()
        }

    }
    
    func updateFirebaseWithUpdatedVars() {
        let docRef = db.collection(DataBase.User).document(user.email)
        let userInfo = User.modelToData(user: user)
        docRef.setData(userInfo, merge: true)
        print("user info merged")
    }
    
    func checkForShortLink() {
        print("if user.hasShortReferral", user.hasShortReferral)
        if user.hasShortReferral { return }
        generateReferralLink()
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
        print("let linkParameter",  linkParameter)
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
            let userRef = self.db.collection(DataBase.User).document(self.user.email)
            userRef.updateData([DataBase.referral_link : stringShortUrl, DataBase.has_short_referral: true])

            return
        }
        
        // use long url instead
        let stringLongURL = "\(longURL)"
        let userRef = db.collection(DataBase.User).document(user.email)
        userRef.updateData([DataBase.referral_link : stringLongURL])
        
        
    }
    
    func logoutUser(disaptchGroup dg: DispatchGroup) {
        print(user.email)
        print(user.isLoggedIn)
        print("trying")
        
        let userRef = db.collection(DataBase.User).document(user.email)
        userRef.updateData([DataBase.is_logged_in : false]) { (err) in
            print("entered")
            if let _ = err {
                print("Error setting is_logged_in")
                dg.customLeave()
                
            }
            else {
                print("is_logged_in_set")
                dg.customLeave()
            }
        }
        userListener?.remove()
        userListener = nil
        user = nil
    }
}
