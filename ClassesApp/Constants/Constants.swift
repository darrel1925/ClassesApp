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
    static let stripeId  = "stripeId"
    static let fcm_token = "fcm_token"
    static let last_name = "last_name"
    static let first_name    = "first_name"
    static let has_premium   = "has_premium"
    static let web_reg_pswd  = "web_reg_pswd"
    static let is_logged_in  = "is_logged_in"
    static let purchase_tire = "purchase_tire"
    static let notifications = "notifications"
    static let num_referrals = "num_referrals"
    static let referral_link = "referral_link"
    static let receive_emails    = "receive_emails"
    static let tracked_classes   = "tracked_classes"
    static let purchase_history  = "purchase_history"
    static let seen_welcome_page = "seen_welcome_page"
    static let course_dict_arr   = "course_dict_arr"
    static let is_email_verified = "is_email_verified"
    static let has_short_referral    = "has_short_referral"
    static let notifications_enabled = "notifications_enabled"
    
    // Notifications & Purchase History
    static let date   = "date"
    static let price  = "price"
    static let old_status  = "old_status"
    static let new_status  = "new_status"
    static let num_credits = "num_credits"
    
    // App Constant Docs
    static let Constants = "Constants"

    // App Constants
    static let price_map     = "price_map"
    static let server_ip     = "server_ip"
    static let terms_url     = "terms_url"
    static let stripe_pk     = "stripe_pk"
    static let privacy_url   = "privacy_url"
    static let server_port   = "server_port"
    static let merchant_id   = "merchant_id"
    static let connect_pswd  = "connect_pswd"
    static let support_email = "support_email"
    static let premium_price = "premium_price"
    static let price_per_class     = "price_per_class"
    static let supported_schools   = "supported_schools"
    static let support_email_pswd  = "support_email_pswd"
    static let registration_pages  = "registration_pages"
    
    // Courses
    static let room  = "room"
    static let days  = "days"
    static let units = "units"
//    static let status    = "status"
    static let section   = "section"
    static let professor = "professor"
    static let class_time   = "class_time"
    static let course_name  = "course_name"
    static let course_type  = "course_type"
    static let course_title = "course_title"
    static let dis_and_labs = "dis_and_labs"

}

struct Tire {
    static let Free = 0
    static let TwoClasses = 1
    static let Unlimited = 2
}

struct Status {
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

struct ReferralLink {
    static let message = "TrackMy tracks your classes and notifies you when they open up! Check it out! \(UserService.user.referralLink)"
}

struct Defaults {
    
    static let wasReferred   = "wasReferred"
    static let referralEmail = "referralEmail"
    static let hasUsedOneReferral = "hasUsedOneReferral"
}
