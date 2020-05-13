//
//  AppDelegate.swift
//  ClassesApp
//
//  Created by Darrel Muonekwu on 3/25/20.
//  Copyright © 2020 Darrel Muonekwu. All rights reserved.
//

import UIKit
import Firebase
import FirebaseAuth
import FirebaseFirestore
import FirebaseMessaging
import UserNotifications

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    var window: UIWindow?
    let gcmMessageIDKey = "gcm.message_id"
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        FirebaseApp.configure()
        if #available(iOS 10.0, *) {
            // For iOS 10 display notification (sent via APNS)
            UNUserNotificationCenter.current().delegate = self
            let authOptions: UNAuthorizationOptions = [.alert, .badge, .sound]
            UNUserNotificationCenter.current().requestAuthorization(
                options: authOptions,
                completionHandler: {_, _ in })
        } else {
            let settings: UIUserNotificationSettings =
                UIUserNotificationSettings(types: [.alert, .badge, .sound], categories: nil)
            application.registerUserNotificationSettings(settings)
        }
        Messaging.messaging().delegate = self
        application.registerForRemoteNotifications()
        
        return true
    }    // to handle incoming url schemes
    
    
    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
        // getting link through app store
        if let dynamicLink = DynamicLinks.dynamicLinks().dynamicLink(fromCustomSchemeURL: url) {
            print("got link though custom url scheme", dynamicLink)
            handleIncomingLink(dynamicLink)
            return true
        }
        // another url that is not my dynamic link'
        return false
    }
    
    func handleIncomingLink(_ dynamicaLink: DynamicLink) {
        guard let url = dynamicaLink.url else {
            print("Thats weird. The url didn't get here")
            return
        }
        print("got the dynamic link from url! \(url)")
        
        // get info from the url
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
            let queryItems = components.queryItems else { return }
        
        
        var email = ""
        
        for query in queryItems {
            print("Perameter \(query.name), Value \(query.value)")
            if query.name == "email"{
                email = query.value ?? "??"
            }
        }
        
        switch dynamicaLink.matchType {
        case .unique:
            // 100% sure this is the link your user clicked on
            print("Unique")
            AppDelegate.addToUserDefaults(email: email)
            break
        case .default:
            // Pretty sure this is the link the user clicked on but dont know for sure
            print("default")
            AppDelegate.addToUserDefaults(email: email)
            break
        case .weak:
            print("weak")
            AppDelegate.addToUserDefaults(email: email)
            // Guessing that this might be the correct link but tbh we dont know for sure
            break
        case .none:
            print("none")
            // There is nothing in this dynamic link
            break
        }
    }
    
    static func addToUserDefaults(email: String) {
        
        // starts out as false if never executed
        let wasReferred = UserDefaults.standard.bool(forKey: Defaults.wasReferred)
        print(Defaults.wasReferred, wasReferred)
        
        // this device already clicked on some referral link at some point
        if wasReferred { return }
            
            // this device has never been referred
        else {
            UserDefaults.standard.set(true, forKey: Defaults.wasReferred)
            UserDefaults.standard.set(false, forKey: Defaults.hasUsedOneReferral)
            UserDefaults.standard.set(email, forKey: Defaults.referralEmail)
            print("device has never been referred")
        }
    }
    
    func presentHomePage() {
        
        let storyboard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
        let apptVC = storyboard.instantiateViewController(withIdentifier: "HomePageController") as! HomePageController
        let navigationController = UINavigationController.init(rootViewController: apptVC)
        self.window?.rootViewController = navigationController
        self.window?.makeKeyAndVisible()
        
//        let storyboard = UIStoryboard(name: "Main", bundle: nil)
//
//        guard let rootVC = storyboard.instantiateViewController(identifier: "HomePageController") as? HomePageController else {
//            print("ViewController not found")
//            return
//        }
//
//        let rootNC = UINavigationController(rootViewController: rootVC)
//        self.window?.rootViewController = rootNC
//        self.window?.makeKeyAndVisible()
        
    }
    
    // MARK: UISceneSession Lifecycle
    
    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }
    
    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Called when the user discards a scene session.
        // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
    }
    
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable: Any]) {
        // If you are receiving a notification message while your app is in the background,
        // this callback will not be fired till the user taps on the notification launching the application.
        // TODO: Handle data of notification
        
        // Print message ID.
        if let messageID = userInfo[gcmMessageIDKey] {
            print("Message ID: \(messageID)")
        }
        
        
        
        print("Notification Recieved  1")
//        presentHomePage()
        // Print full message.
        print(userInfo)
    }
    
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable: Any],
                     fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        // If you are receiving a notification message while your app is in the background,
        // this callback will not be fired till the user taps on the notification launching the application.
        // TODO: Handle data of notification
        
        if ( application.applicationState == .active){
            print("1")
        }
        else if ( application.applicationState == .background){
            print("2")
        }
            // app was already in the foreground
        else if ( application.applicationState == .inactive){
            print("3")
        }
            // app was just brought from background to foreground
        else {
            print("4")
        }
        print("Notification 12")
//        presentHomePage()
        // Print full message.
        print(userInfo)
        
        completionHandler(UIBackgroundFetchResult.newData)
    }    
}

@available(iOS 10, *)
extension AppDelegate : UNUserNotificationCenterDelegate {
    
    // When you recieve notification while in app
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification,
                                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        let userInfo = notification.request.content.userInfo
        
        if let messageID = userInfo[gcmMessageIDKey] {
            print("Message ID: \(messageID)")
        }
        
        print("Notificaiton 10")
//        presentHomePage()
        
        print(userInfo)
        
        // Change this to your preferred presentation option
        completionHandler([.badge, .sound, .alert])
    }
    
    // When i click on notification in app or in background
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                didReceive response: UNNotificationResponse,
                                withCompletionHandler completionHandler: @escaping () -> Void) {
        let userInfo = response.notification.request.content.userInfo
        // Print message ID.
        if let messageID = userInfo[gcmMessageIDKey] {
            print("Message ID: \(messageID)")
        }
        print(userInfo)
        print("Notificaiton 11")
//        presentHomePage()
        
        
        completionHandler()
    }
}


// in order ro register your app to recieve notifications
extension AppDelegate: MessagingDelegate {
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String) {
        print("\nFirebase registration token: \(fcmToken)\n")
        let dataDict:[String: String] = ["token": fcmToken]
        NotificationCenter.default.post(name: Notification.Name("FCMToken"), object: nil, userInfo: dataDict)
        // TODO: If necessary send token to application server.
        // Note: This callback is fired at each app startup and whenever a new token is generated.
        // UserService.fcmToken = fcmToken
    }
    
}
