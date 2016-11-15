//
//  AppDelegate.swift
//  socialApp
//
//  Created by Oleg Pavlichenkov on 08/11/2016.
//  Copyright © 2016 Oleg Pavlichenkov. All rights reserved.
//

import UIKit
import Firebase
import FBSDKLoginKit
import Google
//import GGLSignIn
import GoogleSignIn
import SwiftKeychainWrapper


@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, GIDSignInDelegate {
    


    var window: UIWindow?


    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        
        FIRApp.configure()
        
        //CGLContext
        
        
        GIDSignIn.sharedInstance().clientID = FIRApp.defaultApp()?.options.clientID
        GIDSignIn.sharedInstance().delegate = self
//        
//        window = UIWindow(frame: UIScreen.main.bounds)
//        let mainVC = LogInVC()
//        let navController = UINavigationController(rootViewController: mainVC)
//
//        window?.rootViewController = navController;
//        window?.makeKeyAndVisible()
        
        return true
    }

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appsourceApplicationropriate. See also applicationDidEnterBackground:.
    }
    
    func application(_ application: UIApplication, open url: URL, sourceApplication: String?, annotation: Any) -> Bool {
        
        return FBSDKApplicationDelegate.sharedInstance().application(application, open: url, sourceApplication: sourceApplication, annotation: annotation)
    }
    
//    func application(_ application: UIApplication, open url: URL, sourceApplication: String?, annotation: Any) -> Bool {
//        if url.absoluteString.range(of: "com.facebook") != nil {
//            print("=== facebook url\n")
//        } else if url.absoluteString.range(of: "com.google") != nil {
//            print("=== google url\n")
//
//        } else {
//            print("=== unknown url\n")
//        }
//        return FBSDKApplicationDelegate.sharedInstance().application(application, open: url, sourceApplication: sourceApplication, annotation: annotation)
//        
//    }

//    func application(_ app: UIApplication, open url: URL, options: [UIApplicationOpenURLOptionsKey : Any] = [:]) -> Bool {
//        print("====2 \(url.absoluteString)]n")
//        
//        if url.absoluteString.range(of: "com.facebook") != nil {
//            //print("=== facebook url\n")
//            
//            
//        } else if url.absoluteString.range(of: "com.google") != nil {
//            print("=== google url\n")
//            
//        } else {
//            print("=== unknown url\n")
//        }
//
//        
//        
//        return GIDSignIn.sharedInstance().handle(
//            url,
//            sourceApplication: options[UIApplicationOpenURLOptionsKey.sourceApplication] as! String,
//            annotation: options[UIApplicationOpenURLOptionsKey.annotation])
//    }
    
    
    public func sign(_ signIn: GIDSignIn!, didSignInFor user: GIDGoogleUser!, withError error: Error!) {
        //Code
        if let error = error {
            print(" === \(error.localizedDescription)\n")
            return
        }
        
        // 
        let authentication = user.authentication
        let credential = FIRGoogleAuthProvider.credential(withIDToken: (authentication?.idToken)!, accessToken: (authentication?.accessToken)!)
        
        //print("=== Google Logged In \(credential.provider)")
        FIRAuth.auth()?.signIn(with: credential, completion: { (gIdUser, error) in
            if error != nil {
                print(" !=== Error! Unable to authenticate with Firebase - \(error) ")
            } else {
                print(" === Successfully authenticated with Firebase ")
                if let gIdUser = gIdUser {
                    let userData = ["provider": credential.provider]
                    DataService.ds.createFirebaseDBUser(uid: gIdUser.uid, userData: userData)
                    if KeychainWrapper.standard.set(gIdUser.uid, forKey: KEY_UID) {
                        //performSegue(withIdentifier: "segueLogInToFeedVC", sender: nil /*User(userName: id)*/)
                    } else {
                        print(" === ERROR saving ID to keychain ")
                    }
                }
                
            }
        })

        
    }
    
    public func sign(_ signIn: GIDSignIn!, didDisconnectWith user:GIDGoogleUser!,
                withError error: Error!) {
        // Perform any operations when the user disconnects from app here.
        // ...
        print("=== Google SignOut")
    }
    

}

