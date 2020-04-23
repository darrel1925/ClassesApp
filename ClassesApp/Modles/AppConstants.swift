//
//  AppConstants.swift
//  ClassesApp
//
//  Created by Darrel Muonekwu on 4/19/20.
//  Copyright © 2020 Darrel Muonekwu. All rights reserved.
//

import Foundation
import FirebaseFirestore

let AppConstants = _AppConstants()

class _AppConstants {
    var year = "2020"
    var quarter = "fall"
    var server_ip = ""
    var server_port = 0
    var merchant_id = ""
    var connect_pswd = ""
    var support_email = ""
    var price_per_class = 199
    var support_email_pswd = ""
    var supported_schools: [String] = ["UCI", "UCLA"]
    var appConstantListener: ListenerRegistration? = nil
    var price_map: [String: Int] = ["1": 199, "3":399, "10":1449]
    
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
            self.year = data[DataBase.year] as? String ?? "2020"
            self.quarter = data[DataBase.quarter] as? String ?? "fall"
            self.server_ip = data[DataBase.server_ip] as? String ?? ""
            self.server_port = data[DataBase.server_port] as? Int ?? 0
            self.price_per_class = data[DataBase.price_per_class] as? Int ?? 199
            self.merchant_id = data[DataBase.merchant_id] as? String ?? ""
            self.connect_pswd = data[DataBase.connect_pswd] as? String ?? ""
            self.support_email = data[DataBase.support_email] as? String ?? ""
            self.support_email_pswd = data[DataBase.support_email_pswd] as? String ?? ""
            self.price_map = data[DataBase.price_map] as? [String:Int] ?? ["1": 199, "3":399, "10":1449]
            self.supported_schools = data[DataBase.supported_schools] as? [String] ?? ["UCI", "UCLA"]
            print(data)
        })
    }
}
