//
//  UserService.swift
//  ClassesApp
//
//  Created by Darrel Muonekwu on 3/26/20.
//  Copyright © 2020 Darrel Muonekwu. All rights reserved.
//

import Foundation
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

        let userRef = db.collection("User").document(email)
        userRef.updateData(["is_logged_in" : true])
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
    }
    
    
    func logoutUser(disaptchGroup dg: DispatchGroup) {
        print(user.email)
        print(user.isLoggedIn)
        print("trying")
        
        let userRef = db.collection("User").document(user.email)
        userRef.updateData(["is_logged_in" : false]) { (err) in
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
