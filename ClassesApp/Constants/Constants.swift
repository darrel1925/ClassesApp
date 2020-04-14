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
    var quarter = ""
    var server_ip = "52.32.147.139"
    var year = "2020"
    var server_port = 5000
    var price_per_class = 149
    var appConstantListener: ListenerRegistration? = nil
    
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
            self.quarter = data["quarter"] as? String ?? ""
            self.server_ip = data["server_ip"] as? String ?? "52.32.147.139"
            self.server_port = data["server_port"] as? Int ?? 5000
            self.price_per_class = data["price_per_class"] as? Int ?? 149
            print("quarter: \(self.quarter)\n server_ip: \(self.server_ip)\n server_port: \(self.server_port)\n price_per_class: \(self.price_per_class)")
        })
    }
}
