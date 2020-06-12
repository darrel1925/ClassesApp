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
    static let Analytics = "Analytics"

    // User
    static let id        = "id"
    static let email     = "email"
    static let school    = "school"
    static let web_reg   = "web_reg"
    static let classes   = "classes"
    static let stripeId  = "stripeId"
    static let fcm_token = "fcm_token"
    static let date_joined   = "date_joined"
    static let app_version   = "app_version"
    static let has_premium   = "has_premium"
    static let web_reg_pswd  = "web_reg_pswd"
    static let is_logged_in  = "is_logged_in"
    static let notifications = "notifications"
    static let num_referrals = "num_referrals"
    static let referral_link = "referral_link"
    static let has_auto_enroll   = "has_auto_enroll"
    static let receive_emails    = "receive_emails"
    static let current_version   = "current_version"
    static let purchase_history  = "purchase_history"
    static let seen_welcome_page = "seen_welcome_page"
    static let course_dict_arr   = "course_dict_arr"
    static let is_email_verified = "is_email_verified"
    static let has_short_referral    = "has_short_referral"
    static let notifications_enabled = "notifications_enabled"
    
    static let has_set_user_poperty = "has_set_user_poperty"
    
    // Notifications & Purchase History
    static let date   = "date"
    static let price  = "price"
    static let old_status  = "old_status"
    static let new_status  = "new_status"
    static let num_credits = "num_credits"
    
    // App Constant Docs
    static let Constants = "Constants"

    // App Constants
    static let routes           = "routes"
    static let subject          = "subject"
    static let message          = "message"
    static let class_info       = "class_info"
    static let display_terms    = "display_terms"
    static let did_send_email   = "did_send_email"
    static let add_class_to_db  = "add_class_to_db"
    static let display_privacy  = "display_privacy"
    static let send_email_route = "send_email_route"

    static let path          = "path"
    static let host          = "host"
    static let scheme        = "scheme"
    static let imageURL      = "imageURL"
    static let appStoreID    = "appStoreID"
    static let metaTagTitle  = "metaTagTitle"
    static let referral_info = "referral_info"
    static let domainURIPrefix    = "domainURIPrefix"
    static let metaTagDescription = "metaTagDescription"
    
    static let my_email      = "my_email"
    static let server_ip     = "server_ip"
    static let terms_url     = "terms_url"
    static let stripe_pk     = "stripe_pk"
    static let privacy_url   = "privacy_url"
    static let merchant_id   = "merchant_id"
    static let domain_name   = "domain_name"
    static let server_port   = "server_port"
    static let support_email = "support_email"
    static let premium_price = "premium_price"
    static let supported_schools   = "supported_schools"
    static let support_email_pswd  = "support_email_pswd"
    static let registration_pages  = "registration_pages"
    static let premium_product_id  = "premium_product_id"
    static let class_look_up_pages = "class_look_up_pages"
    static let current_app_version = "current_app_version"

    // Course
    static let year        = "year"
    static let emails      = "emails"
    static let quarter     = "quarter"
    static let code        = "code"
    static let status      = "status"
    static let auto_enroll_emails = "auto_enroll_emails"

    // Courses
    static let room  = "room"
    static let days  = "days"
    static let time  = "time"
    static let name  = "name"
    static let type  = "type"
    static let title = "title"
    static let units = "units"
    static let section      = "section"
    static let professor    = "professor"
    static let date_added   = "date_added"
    static let dis_and_labs = "dis_and_labs"
    static let restrictions = "restrictions"
    

    // Analytics
    static let faq_viewed          = "faq_viewed"
    static let num_courses         = "num_courses"
    static let class_tracked       = "class_tracked"
    static let email_verified      = "email_verified"
    static let sign_up_clicked     = "sign_up_clicked"
    static let num_classes_tracked     = "num_classes_tracked"
    static let copied_link_to_clip     = "copied_link_to_clip"
    static let signed_up_from_referral = "signed_up_from_referral"
    static let viewed_premium_details_from_store  = "viewed_premium_details_from_store"
    static let viewed_premium_details_from_welcome  = "viewed_premium_details_from_welcome"
    static let premium = "premium"
    static let purchases = "purchases"
    
    // Animations
    static let should_prompt_update_frequency = "should_prompt_update_frequency"
    static let seen_home_tap_directions       = "seen_home_tap_directions"
    static let should_prompt_update           = "should_prompt_update"
    static let seen_whats_new                 = "seen_whats_new"
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
    static var path: String { return AppConstants.referral_info[DataBase.path] ?? ""}
    static var host: String { return AppConstants.referral_info[DataBase.host] ?? ""}
    static var scheme: String { return AppConstants.referral_info[DataBase.scheme] ?? ""}
    static var imageURL: String { return AppConstants.referral_info[DataBase.imageURL] ?? ""}
    static var appStoreID: String { return AppConstants.referral_info[DataBase.appStoreID] ?? ""}
    static var metaTagTitle: String { return AppConstants.referral_info[DataBase.metaTagTitle] ?? ""}
    static var domainURIPrefix: String { return AppConstants.referral_info[DataBase.domainURIPrefix] ?? ""}
    static var metaTagDescription: String { return AppConstants.referral_info[DataBase.metaTagDescription] ?? ""}
    static var message: String = "TrackMy tracks your classes and notifies you when they open up! Check it out! \(UserService.user.referralLink)"
    }

struct Routes {
    static let scheme           = AppConstants.routes[DataBase.scheme]
    static let class_info       = AppConstants.routes[DataBase.class_info]
    static let display_terms    = AppConstants.routes[DataBase.display_terms]
    static let display_privacy  = AppConstants.routes[DataBase.display_privacy]
    static let send_email_route = AppConstants.routes[DataBase.send_email_route]
}

struct Defaults {
    static let wasReferred     = "wasReferred"
    static let referralEmail   = "referralEmail"
    static let promptForUpdate = "promptForUpdate"
    static let hasUsedOneReferral   = "hasUsedOneReferral"
    static let hasSeenWelcomeScreen = "hasSeenWelcomeScreen"
}

struct Restrictions {
    static let A = "Prerequisite required"
    static let B = "Authorization required"
    static let C = "Fee required"
    static let D = "Pass/not pass option only"
    static let E = "Freshmen only"
    static let F = "Sophomores only"
    static let G = "Lower-division only"
    static let H = "Juniors only"
    static let I = "Seniors only"
    static let J = "Upper-division only"
    static let K = "Graduate only"
    static let L = "Major only"
    static let M = "Non-major only"
    static let N = "School major only"
    static let O = "Non-school major only"
    static let S = "Satisfactory/unsatisfactory only"
    static let R = "Biomedical pass/fail course (School of Medicine only)"
    static let X = "Separate authorization codes required to add, drop, or change"
    
    static let restrictions: [String] = [
        "A - Prerequisite required",
        "B - Authorization required",
        "C - Fee required",
        "D - Pass/not pass option only",
        "E - Freshmen only",
        "F - Sophomores only",
        "G - Lower-division only",
        "H - Juniors only",
        "I - Seniors only",
        "J - Upper-division only",
        "K - Graduate only",
        "L - Major only",
        "M - Non-major only",
        "N - School major only",
        "O - Non-school major only",
        "S - Satisfactory/unsatisfactory only",
        "R - Biomedical pass/fail course (School of Medicine only)",
        "X - Separate authorization codes required to add, drop, or change",
        ]
}
