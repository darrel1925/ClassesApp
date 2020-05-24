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
    var my_email  = ""
    var server_ip = ""
    var terms_url = ""
    var stripe_pk = ""
    var server_port = 0
    var privacy_url = ""
    var merchant_id = ""
    var domain_name = ""
    var support_email = ""
    var premium_price = 499
    var support_email_pswd  = ""
    var premium_product_id  = ""
    var has_not_purchased   = true
    var has_confirmed_email = false
    
    var authenticated: Bool { return (my_email == UserService.user.email) && has_confirmed_email }
    var supported_schools: [String] = ["UCI", "UCLA"]
    var appConstantListener: ListenerRegistration? = nil
    var registration_pages: [String: String] = [:]
    var class_look_up_pages: [String: String] = [:]
    var referral_info: [String: String] = [:]
    var routes: [String: String] = [:]
    
    func initalizeConstants() {
        // Need settings bc
        let settings = FirestoreSettings()
        settings.isPersistenceEnabled = false
        let db = Firestore.firestore()
        db.settings = settings
        let constanatsRef = db.collection(DataBase.AppConstants).document(DataBase.Constants)
        // if i change an app constant document, it will always be up to date in our app
        appConstantListener = constanatsRef.addSnapshotListener({ (snap, error) in
            if let _ = error {
                print("could not add snapShotListener :/")
                return
            }
            // if we can get app info from the server
            guard let data = snap?.data() else { return }
//            print(data)
            // add it to out self so we can access it globally
            self.year = data[DataBase.year] as? String ?? "2020"
            self.quarter = data[DataBase.quarter] as? String ?? "fall"
            self.my_email  = data[DataBase.my_email] as? String ?? ""
            self.server_ip = data[DataBase.server_ip] as? String ?? ""
            self.terms_url = data[DataBase.terms_url] as? String ?? ""
            self.stripe_pk = data[DataBase.stripe_pk] as? String ?? ""
            self.privacy_url = data[DataBase.privacy_url] as? String ?? ""
            self.server_port = data[DataBase.server_port] as? Int ?? 0
            self.premium_price = data[DataBase.premium_price] as? Int ?? 499
            self.merchant_id = data[DataBase.merchant_id] as? String ?? ""
            self.domain_name = data[DataBase.domain_name] as? String ?? ""
            self.support_email = data[DataBase.support_email] as? String ?? ""
            self.premium_product_id = data[DataBase.premium_product_id] as? String ?? ""
            self.support_email_pswd = data[DataBase.support_email_pswd] as? String ?? ""
            self.has_not_purchased = data[DataBase.has_not_purchased] as? Bool ?? false
            self.has_confirmed_email = data[DataBase.has_confirmed_email] as? Bool ?? false
            self.referral_info = data[DataBase.referral_info] as? [String: String] ?? [:]
            self.supported_schools = data[DataBase.supported_schools] as? [String] ?? ["UCI", "UCLA"]
            self.registration_pages = data[DataBase.registration_pages] as? [String: String] ?? [:]
            self.class_look_up_pages = data[DataBase.class_look_up_pages] as? [String: String] ?? [:]
            self.routes = data[DataBase.routes] as? [String: String] ?? [:]
            Stripe.setDefaultPublishableKey(self.stripe_pk)

//            print(data)
        })
    }
}
