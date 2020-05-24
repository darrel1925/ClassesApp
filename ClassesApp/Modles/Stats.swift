//
//  Stats.swift
//  ClassesApp
//
//  Created by Darrel Muonekwu on 5/5/20.
//  Copyright © 2020 Darrel Muonekwu. All rights reserved.
//

import UIKit
import Firebase
import FirebaseFirestore

let Stats = _Stats()

final class _Stats {
    /*
     Limites to 10 text parameter reports and 40 numeric parameter reports with Firebase Analytics across my entire project
     */
    
    init() {
        // initalize school with user defaults?
    }
    
    func setUserProperty(school: String) {
        print("prop set")
        Analytics.setUserProperty(UserService.user.school, forName: DataBase.school)
    }
    
    func logPurchase() {
        Analytics.logEvent(AnalyticsEventPurchase, parameters: nil)
    }
    
    func logLinkShared() {
         Analytics.logEvent(AnalyticsEventShare, parameters: nil)
    }
    
    func logAppOpened() { // <-- figure out where you want to put this and how it should be tracked
        if UserService.user == nil { return }
        Analytics.logEvent(AnalyticsEventAppOpen, parameters: nil)
    }

    func logPremiumShown() {
        Analytics.logEvent(AnalyticsEventPresentOffer, parameters: nil)
    }
    
    
    func logRevievedNotification() {

    }

    func logSignUp() {
        Analytics.logEvent(AnalyticsEventSignUp, parameters: nil)
    }
    
    func logFAQView() {
        Analytics.logEvent(DataBase.faq_viewed, parameters: nil)
    }

    func logSignUpClicked() {
        Analytics.logEvent(DataBase.sign_up_clicked, parameters: nil)
    }
    
    func logCopiedLinkToClip() {
        Analytics.logEvent(DataBase.copied_link_to_clip, parameters: nil)
    }
    
    func logSignedUpFromReferral() {
        Analytics.logEvent(DataBase.signed_up_from_referral, parameters: nil)
    }
    
    func logEmailVerified() {
        Analytics.logEvent(DataBase.email_verified, parameters: nil)
    }
    
    func logNumClassesTracked(numCourses: Int) { // <-- figure out a better was to analyize this info
        Analytics.logEvent(DataBase.num_classes_tracked, parameters: [DataBase.num_courses: numCourses])
    }
    
    func logTrackedClass(course: Course) {
        Analytics.logEvent(DataBase.class_tracked, parameters: [DataBase.code: course.code])
    }
    
    func setScreenName(screenName: String, screenClass: String) {
//        Analytics.setScreenName(screenName, screenClass: screenClass)
    }
}
