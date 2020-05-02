//
//  AppConstants.swift
//  ClassesApp
//
//  Created by Darrel Muonekwu on 4/19/20.
//  Copyright © 2020 Darrel Muonekwu. All rights reserved.
//

import Foundation
import FirebaseFirestore
import Stripe
let AppConstants = _AppConstants()

class _AppConstants {
    var year = "2020"
    var quarter = "fall"
    var server_ip = ""
    var terms_url = ""
    var stripe_pk = ""
    var server_port = 0
    var privacy_url = ""
    var merchant_id = ""
    var connect_pswd = ""
    var support_email = ""
    var price_per_class = 199
    var premium_price = 499
    var support_email_pswd = ""
    var server_ports: [Int] = []
    var supported_schools: [String] = ["UCI", "UCLA"]
    var appConstantListener: ListenerRegistration? = nil
    var registration_pages: [String: String] = [:]
    var price_map: [String: Int] = ["1": 199, "3":399, "10":1449]
    
    func initalizeConstants() {
        let db = Firestore.firestore()
        let userRef = db.collection(DataBase.AppConstants).document(DataBase.Constants)
        // if i change an app constant document, it will always be up to date in our app
        appConstantListener = userRef.addSnapshotListener({ (snap, error) in
            if let _ = error {
                print("could not add snapShotListener :/")
                return
            }
            // if we can get app info from the server
            guard let data = snap?.data() else { return }
            
            // add it to out self so we can access it globally
            self.year = data[DataBase.year] as? String ?? "2020"
            self.quarter = data[DataBase.quarter] as? String ?? "fall"
            self.server_ip = data[DataBase.server_ip] as? String ?? ""
            self.terms_url = data[DataBase.terms_url] as? String ?? ""
            self.stripe_pk = data[DataBase.stripe_pk] as? String ?? ""
            self.privacy_url = data[DataBase.privacy_url] as? String ?? ""
            self.server_port = data[DataBase.server_port] as? Int ?? 0
            self.premium_price = data[DataBase.premium_price] as? Int ?? 499
            self.price_per_class = data[DataBase.price_per_class] as? Int ?? 199
            self.merchant_id = data[DataBase.merchant_id] as? String ?? ""
            self.connect_pswd = data[DataBase.connect_pswd] as? String ?? ""
            self.support_email = data[DataBase.support_email] as? String ?? ""
            self.server_ports = data[DataBase.server_ports] as? [Int] ?? []
            self.support_email_pswd = data[DataBase.support_email_pswd] as? String ?? ""
            self.price_map = data[DataBase.price_map] as? [String:Int] ?? ["1": 199, "3":399, "10":1449]
            self.supported_schools = data[DataBase.supported_schools] as? [String] ?? ["UCI", "UCLA"]
            self.registration_pages = data[DataBase.registration_pages] as? [String: String] ?? [:]
            Stripe.setDefaultPublishableKey(self.stripe_pk)

//            print(data)
        })
    }
}
