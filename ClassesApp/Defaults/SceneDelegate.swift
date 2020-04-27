//
//  SceneDelegate.swift
//  ClassesApp
//
//  Created by Darrel Muonekwu on 3/25/20.
//  Copyright © 2020 Darrel Muonekwu. All rights reserved.
//

import UIKit
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
        //
        //
        // if user is logged in
        if ((user) != nil) {
            
            isUserDisabled(user: user!)
            // if user's email is not verified
            if !user!.isEmailVerified { print("email not verified"); return }
            
            print("user:\(user?.email ?? "email not found") already logged in\n\n")
            guard let windowScene = (scene as? UIWindowScene) else { return }
            self.window = UIWindow(windowScene: windowScene)
            
            UserService.dispatchGroup.enter()
            UserService.getCurrentUser(email: user?.email ?? "no email found at start") // leaves dispatch group
            
            UserService.dispatchGroup.notify(queue: .main, execute: {
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
    
    
    func checkIfUserLoggedIn() {
        Auth.auth().addStateDidChangeListener { auth, user in
            if let user = user { // user already logged in
                print("user already logged in")
                UserService.dispatchGroup.enter()
                
                UserService.getCurrentUser(email: user.email ?? "no email found at start")
                UserService.dispatchGroup.notify(queue: .main, execute: {
                    self.presentHomePage()
                })
            }
            else {
                print("User not logged in \n")
            }
        }
    }
    
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
        user.reload(completion: { (error) in
            if error != nil {
                if let error = AuthErrorCode(rawValue: error!._code) {
                    print("IS DISABLED", error.errorMessage)
                    print("IS DISABLED raw value", error.rawValue)
                return
                }
            }
            print("no error")
        })
        print("checked disabled")
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
        UserService.isLoggedIn = false // <- to allow user logon into new account and have fcm update automatically
        
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

