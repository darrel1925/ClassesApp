//
//  StripeAPI.swift
//  ClassesApp
//
//  Created by Darrel Muonekwu on 4/3/20.
//  Copyright © 2020 Darrel Muonekwu. All rights reserved.
//

import Foundation
import Stripe
import FirebaseFunctions

let StripeAPI = _StripeAPI()

class _StripeAPI: NSObject, STPCustomerEphemeralKeyProvider {
    
    // This func is called automatically
    func createCustomerKey(withAPIVersion apiVersion: String, completion: @escaping STPJSONResponseCompletionBlock) {
        
        print("Stripe Id: \(UserService.user.stripeId)")
        print("API Version: \(apiVersion)")
        let data = [
            "customer_id": UserService.user.stripeId,
            "stripe_version": apiVersion
        ]
        
        print("about to connect")
        Functions.functions().httpsCallable("createEphemeralKey").call(data) { (result, error) in
            print("got a responce")
            
            if let error = error {
                print("Error Creating Ephemeral Key: \(error.localizedDescription)")
                completion(nil, error)
                return
            }
            
            guard let key = result?.data as? [String: Any] else {
                completion(nil, error)
                return
            }
            
            print("got ephemeral Key")
            completion(key, nil)
        }
    }
}
