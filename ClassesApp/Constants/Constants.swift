//
//  Constants.swift
//  ClassesApp
//
//  Created by Darrel Muonekwu on 4/8/20.
//  Copyright © 2020 Darrel Muonekwu. All rights reserved.
//

import Foundation
import FirebaseFirestore

let AppConstants = _AppConstants()

class _AppConstants {
    var quarter = "fall"
    var server_ip = "52.32.147.139"
    var year = "2020"
    var server_port = 17821
    var price_per_class = 199
    var appConstantListener: ListenerRegistration? = nil
    var merchant_id = "merchant.com.darrelmuonekwu.ClassesApp"
    var price_map: [String: Int] = ["1": 199, "3":399, "10":1449]
    var supported_schools: [String] = ["UCI", "Hoowhah"]
    
    func initalizeConstants() {
        let db = Firestore.firestore()
        let userRef = db.collection("AppConstants").document("Constants")
        // if i change an app constant document, it will always be up to date in our app
        appConstantListener = userRef.addSnapshotListener({ (snap, error) in
            if let _ = error {
                print("could not add snapShotListener :/")
                return
            }
            // if we can app info from the server
            guard let data = snap?.data() else { return }
            
            // add it to out self so we can access it globally
            self.quarter = data["year"] as? String ?? "2020"
            self.quarter = data["quarter"] as? String ?? "fall"
            self.server_ip = data["server_ip"] as? String ?? "52.32.147.139"
            self.server_port = data["server_port"] as? Int ?? 17821
            self.price_per_class = data["price_per_class"] as? Int ?? 199
            self.merchant_id = data["merchant_id"] as? String ?? "merchant.com.darrelmuonekwu.ClassesApp"
            self.price_map = data["price_map"] as? [String:Int] ?? ["1": 199, "3":399, "10":1449]
            self.supported_schools = data["supported_schools"] as? [String] ?? ["UCI", "Hoowhah"]
            print(data)
        })
    }
}


struct DataBase {
    
    // Collections
    static let User  = "User"
    static let Class = "Class"
    static let AppConstants = "AppConstants"

    // Class
    static let year    = "year"
    static let emails  = "emails"
    static let quarter = "quarter"
    static let course_code = "course_code"
    static let curr_status = "curr_status"

    // User
    static let id        = "id"
    static let email     = "email"
    static let school    = "school"
    static let web_reg   = "web_reg"
    static let classes   = "classes"
    static let credits   = "credits"
    static let stripeId  = "stripeId"
    static let fcm_token = "fcm_token"
    static let last_name = "last_name"
    static let first_name    = "first_name"
    static let web_reg_pswd  = "web_reg_pswd"
    static let is_logged_in  = "is_logged_in"
    static let notifications = "notifications"
    static let receive_emails   = "receive_emails"
    static let tracked_classes   = "tracked_classes"
    static let purchase_history = "purchase_history"
    
    // Notifications & Purchase History
    static let date   = "date"
    static let price  = "price"
    static let old_status  = "old_status"
    static let new_status  = "new_status"
    static let num_credits = "num_credits"
}

struct Response {
    static let OPEN    = "OPEN"
    static let Waitl   = "Waitl"
    static let FULL    = "FULL"
    static let NewOnly = "NewOnly"
    static let Error   = "Error"
}

struct Schools {
    static let UCI  = "UCI"
    static let UCLA = "UCLA"
}
