//
//  Constants.swift
//  ClassesApp
//
//  Created by Darrel Muonekwu on 4/8/20.
//  Copyright © 2020 Darrel Muonekwu. All rights reserved.
//

import Foundation

struct DataBase {
    
    // Collections
    static let User  = "User"
    static let Class = "Class"
    static let AppConstants = "AppConstants"
    static let AppVariables = "AppVariables"

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
    static let receive_emails    = "receive_emails"
    static let tracked_classes   = "tracked_classes"
    static let purchase_history  = "purchase_history"
    static let seen_welcome_page = "seen_welcome_page"
    static let notifications_enabled = "notifications_enabled"
    
    // Notifications & Purchase History
    static let date   = "date"
    static let price  = "price"
    static let old_status  = "old_status"
    static let new_status  = "new_status"
    static let num_credits = "num_credits"
    
    // App Constants
    static let price_map     = "price_map"
    static let server_ip     = "server_ip"
    static let server_port   = "server_port"
    static let merchant_id   = "merchant_id"
    static let connect_pswd  = "connect_pswd"
    static let support_email = "support_email"
    static let price_per_class    = "price_per_class"
    static let supported_schools  = "supported_schools"
    static let support_email_pswd = "support_email_pswd"
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
