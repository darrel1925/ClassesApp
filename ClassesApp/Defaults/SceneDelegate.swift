//
//  SceneDelegate.swift
//  ClassesApp
//
//  Created by Darrel Muonekwu on 3/25/20.
//  Copyright © 2020 Darrel Muonekwu. All rights reserved.
//

import UIKit
import Firebase
import FirebaseAuth

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    
    var window: UIWindow?
    var windowScene: UIWindowScene!
    
    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        // Use this method to optionally configure and attach the UIWindow `window` to the provided UIWindowScene `scene`.
        // If using a storyboard, the `window` property will automatically be initialized and attached to the scene.
        // This delegate does not imply the connecting scene or session are new (see `application:configurationForConnectingSceneSession` instead).
        
        let user = Auth.auth().currentUser
        AppConstants.initalizeConstants()
        
        // if user is logged in
        if ((user) != nil) {
            
//            isUserDisabled(user: user!)
            
            print("user:\(user?.email ?? "email not found") already logged in\n\n")
            guard let windowScene = (scene as? UIWindowScene) else { return }
            self.window = UIWindow(windowScene: windowScene)
            
            UserService.getCurrentUser(email: user?.email ?? "no email found at start", completion: {
                if UserService.user == nil { self.presentSplashScreen(); return } // if user is logged in but account is deleted (shouldnt ever happen)
                
                let storyboard = UIStoryboard(name: "Main", bundle: nil)
                
                guard let rootVC = storyboard.instantiateViewController(identifier: "HomePageController") as? HomePageController else {
                    print("ViewController not found")
                    return
                }
                
                let rootNC = UINavigationController(rootViewController: rootVC)
                self.window?.rootViewController = rootNC
                self.window?.makeKeyAndVisible()
            })
        }
        else {
            print("user is NOT already logged in\n\n")
        }
    }
    
    
    func presentSplashScreen() {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        
        guard let rootVC = storyboard.instantiateViewController(identifier: "SplashScreenController") as? SplashScreenController else {
            print("ViewController not found")
            return
        }
        
        let rootNC = UINavigationController(rootViewController: rootVC)
        rootNC.isNavigationBarHidden = true
        self.window?.rootViewController = rootNC
        self.window?.makeKeyAndVisible()
    }
    
    
    //    func checkIfUserLoggedIn() {
    //        Auth.auth().addStateDidChangeListener { auth, user in
    //            if let user = user { // user already logged in
    //                print("user already logged in")
    //                UserService.dispatchGroup.enter()
    //
    //                UserService.getCurrentUser(email: user.email ?? "no email found at start")
    //                UserService.dispatchGroup.notify(queue: .main, execute: {
    //                    self.presentHomePage()
    //                })
    //            }
    //            else {
    //                print("User not logged in \n")
    //            }
    //        }
    //    }
    
    func presentHomePage(){
        // show customer home page
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        guard let rootVC = storyboard.instantiateViewController(identifier: "HomePageController") as? HomePageController else {
            print("ViewController not found")
            return
        }
        let rootNC = UINavigationController(rootViewController: rootVC)
        self.window?.rootViewController = rootNC
        self.window?.makeKeyAndVisible()
    }
    
    func isUserDisabled(user: FirebaseAuth.User) {
        //        user.reload(completion: { (error) in
        //            if error != nil {
        //                print("Error reloading user \(error?.localizedDescription ?? "")")
        //            }
        //        })
        //        print("checked disabled")
    }
    
    
    // handle universal URLs (when user clicks on dynamic link and has app installed)
    func scene(_ scene: UIScene, continue userActivity: NSUserActivity) {
        print("ENTEREED URL")
        if let incomingURL = userActivity.webpageURL {
            print("incoming URL is \(incomingURL)")
            
            // turns link into dynamic link object
            DynamicLinks.dynamicLinks().handleUniversalLink(incomingURL) { (dynamicLink, error) in
                if let error = error {
                    print("Found and err! \(error.localizedDescription)")
                }
                if let dynamicLink = dynamicLink {
                    self.handleIncomingLink(dynamicLink)
                }
            }
        }
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
            print("Perameter \(query.name), Value \(String(describing: query.value))")
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
        @unknown default:
            print("none")
            
        }
    }
    
    func reloadUser() {
        /*
         If user just verified their email without closing the app, this will refresh their user object to reflect that
         */
        
        // if user has not been logged in
        if UserService.user == nil { return }
        
        let isVerified = UserService.user.isEmailVerified
        if isVerified { return }
        print("not verified")
        
        guard let user = Auth.auth().currentUser else { return }
        user.reload(completion: {error in
            if let err = error {
                print("error reloading user", err.localizedDescription)
            }
            print("reload successful")
        })
    }
    
    func sceneDidDisconnect(_ scene: UIScene) {
        // Called as the scene is being released by the system.
        // This occurs shortly after the scene enters the background, or when its session is discarded.
        // Release any resources associated with this scene that can be re-created the next time the scene connects.
        // The scene may re-connect later, as its session was not neccessarily discarded (see `application:didDiscardSceneSessions` instead).
    }
    
    func sceneDidBecomeActive(_ scene: UIScene) {
        // Called when the scene has moved from an inactive state to an active state.
        // Use this method to restart any tasks that were paused (or not yet started) when the scene was inactive.
        UIApplication.shared.applicationIconBadgeNumber = 0
        
        if UserService.user == nil { return }
        
        reloadUser() // <-- to refresh user object for email verifications
        Stats.logAppOpened() // <-- log each time a user opens app
        UserService.setFCM() // <-- update fcm token
        UserService.setAppVersion() // <-- update user's app version
        UserService.resetBadgeCount() // <-- set badge count to 0
    }
    
    func sceneWillResignActive(_ scene: UIScene) {
        // Called when the scene will move from an active state to an inactive state.
        // This may occur due to temporary interruptions (ex. an incoming phone call).
    }
    
    func sceneWillEnterForeground(_ scene: UIScene) {
        // Called as the scene transitions from the background to the foreground.
        // Use this method to undo the changes made on entering the background.
    }
    
    func sceneDidEnterBackground(_ scene: UIScene) {
        // Called as the scene transitions from the foreground to the background.
        // Use this method to save data, release shared resources, and store enough scene-specific state information
        // to restore the scene back to its current state.
    }
    
    
}

