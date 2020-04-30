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
        
        self.dispatchGroup.notify(queue: .main) {
            self.updateFirebaseWithUpdatedVars()
        }
    }
    
    func updateFirebaseWithUpdatedVars() {
        let docRef = db.collection(DataBase.User).document(user.email)
        let userInfo = User.modelToData(user: user)
        docRef.setData(userInfo, merge: true)
        print("user info merged")
    }
    
    func generateReferralLink() {
        // Create url that will get parsed and give you the parameters
        var components = URLComponents()
        components.scheme = "https"
        components.host = "www.apple.com" // should be appstore link
        components.path = "/ios/app-store"
        
        let userInfoQueryItem = URLQueryItem(name: "email", value: UserService.user.email)
        components.queryItems = [userInfoQueryItem]
        
        // Full url with all parameters included
        guard let linkParameter = components.url else { return }
        
        // Create the big dynamic link
        guard let shareLink = DynamicLinkComponents.init(link: linkParameter, domainURIPrefix: "https://trackmy.page.link") else { return }
        
        if let bundleId = Bundle.main.bundleIdentifier {
            shareLink.iOSParameters = DynamicLinkIOSParameters(bundleID: bundleId)
        }
        
        // Where to direct users if app is not installed
        shareLink.iOSParameters?.appStoreID = "962194608"
        shareLink.iOSParameters?.customScheme = "962194608"
        
        // Used to present how link is displayed and to populate inbetween screen before app store
        shareLink.socialMetaTagParameters = DynamicLinkSocialMetaTagParameters()
        shareLink.socialMetaTagParameters?.title = "Time To Get Tracking!"
        shareLink.socialMetaTagParameters?.descriptionText = "No more late-night discussions or bad professors. Let TrackMy get you the classes you deserve! Thank \(user.email) for the referral!"
        
        if let imageURL = URL( string: "https://kissflow.com/wp-content/uploads/2018/11/Purchase-Order-Tracking_Blog.png") {
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
            
            guard let url = url else { return }
            print("Short dynamic URL is \(url)")
            return
        }
        // user long url instead
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
                print("is_log_in_set")
                dg.customLeave()
            }
        }
        print("here")
        userListener?.remove()
        userListener = nil
        user = nil
    }
}
