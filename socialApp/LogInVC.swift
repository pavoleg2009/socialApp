//
//  ViewController.swift
//  socialApp
//
//  Created by Oleg Pavlichenkov on 08/11/2016.
//  Copyright © 2016 Oleg Pavlichenkov. All rights reserved.
//

import UIKit
import FBSDKCoreKit
import FBSDKLoginKit
import Firebase
import SwiftKeychainWrapper
import GoogleSignIn


class LogInVC: UIViewController, GIDSignInUIDelegate {
    
    var activeUser:FIRUser!
    
    @IBOutlet weak var emailField: MyTextField!
    @IBOutlet weak var passwordField: MyTextField!
//
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        GIDSignIn.sharedInstance().uiDelegate = self
        
        
        FIRAuth.auth()?.addStateDidChangeListener { auth, user in
            if let user = user {
                // User is signed in. - why is it colled twice?
                if !user.isEqual(self.activeUser) {
                    self.activeUser = user
                    print("=== FIRAuth.auth()?.addStateDidChangeListener: \(user.email!)\n")
                self.performSegue(withIdentifier: "segueLogInToFeedVC", sender: nil)
                }
                
                
                
            } else {
                self.activeUser = nil
                print("=== from viewDidLoad: user = nil (LOGGED OUT)\n")
                // No user is signed in.
              //  self.userEmailLabel.text = "no user logged"
            }
        }
        
 
    }
    
    override func viewDidAppear(_ animated: Bool) {
        if let retrievedString: String = KeychainWrapper.standard.string(forKey: KEY_UID) {
            //print("=== Seage to FeedVC with retrievedString: \(retrievedString)")
           // performSegue(withIdentifier: "segueLogInToFeedVC", sender: nil  /* User(userName:retrievedString */)
            
        } else {
            //print(" === KeychainWrapper.standard.string(forKey: KEY_UID) = NIL ")
        }
    }

    @IBAction func fbButtonTapped(_ sender: Any) {
        
        let facebookLogin = FBSDKLoginManager()
        facebookLogin.logIn(withReadPermissions: ["email"], from: self) { (result, error) in
            if error != nil {
                print(" === Unable to auth with Facebook === \(error) ")
            } else if result?.isCancelled == true {
                print(" === User cancelled Facebook auth ")
            } else {
                print(" === Successfully authenticated with Facebook ")
                let credential = FIRFacebookAuthProvider.credential(withAccessToken: FBSDKAccessToken.current().tokenString)
                
                self.firebaseAuth(credential)
            }
        }
    }
    
    @IBAction func googleButtonTapped(_ sender: Any) {
      //  sign(GIDSignIn!, didSignInFor: GIDGoogleUser!, withError: Error?)
      
        
    }
    
    @IBAction func githubButtonTapped(_ sender: Any) {
    }
    
    
    func firebaseAuth(_ credential: FIRAuthCredential) {
        FIRAuth.auth()?.signIn(with: credential, completion: { (gIdUser, error) in
            if error != nil {
                print(" !=== Error! Unable to authenticate with Firebase - \(error) ")
            } else {
                print(" === Successfully authenticated with Firebase ")
                if let gIdUser = gIdUser {
                    let userData = ["provider": credential.provider]
                    self.completeSignIn(id: gIdUser.uid, userData: userData)
                }
                
            }
        })
    }

    
    
    @IBAction func loginButtonTapped(_ sender: Any) {
        if let email = emailField.text, let password = passwordField.text {
            FIRAuth.auth()?.fetchProviders(forEmail: email, completion: { (providers, error) in
                if error != nil {
                    print(" !=== Error fetching auth providers for email: \(email) ====: \(error.debugDescription) ")
                } else {
                    //
                    if providers != nil {
                        // loggin in with existing email user
                        FIRAuth.auth()?.signIn(withEmail: email, password: password, completion: { (gIdUser, error) in
                            if error == nil {
                                print(" === User Successfully authenticated with Email ")
                                if let gIdUser = gIdUser { // GIDGoogleUser!
                                    let userData = ["provider": gIdUser.providerID]
                                    self.completeSignIn(id: gIdUser.uid, userData: userData)

                                }
                                
                            } else {
                                print(" !=== Error! during authenticating with email/password: \(error.debugDescription) ")
                            }
                        })
                    } else {
                        print(" === User (email) not found. Please check email or SignIn ")
                    }
                }
            })
        }
    }

    @IBAction func signInButtonTapped(_ sender: Any) {
       performSegue(withIdentifier: "segueLogInToUserVC", sender: nil)
        
    }
    
    
    func completeSignIn(id: String, userData: Dictionary<String, String>) {
        DataService.ds.createFirebaseDBUser(uid: id, userData: userData)
        if KeychainWrapper.standard.set(id, forKey: KEY_UID) {
            performSegue(withIdentifier: "segueLogInToFeedVC", sender: nil /*User(userName: id)*/)
        } else {
            print(" === ERROR saving ID to keychain ")
        }
        
    }

    

    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "segueLogInToFeedVC" {
            if let feedVC = segue.destination as? FeedVC {
//                if let user = sender as? User {
//                    feedVC.currentUser = user
                
                //print(" !!! === From LoginVC to FeedVC \n")
//                }
            }
        }
        
        if segue.identifier == "segueLogInToUserVC" {
            //open UserProfileVC for adding new user
            if let userProfileVC = segue.destination as? UserVC {
                userProfileVC.openedFor = .insert
            }
        }
    }
    
    //Google SignIn
    
    
//    func sign(_ signIn: GIDSignIn!, didSignInFor user: GIDGoogleUser!, withError error: Error?) {
//        print("=== 0 ")
//        if let error = error {
//            //self.showMessagePrompt(error.localizedDescription)
//            print("=== 1 ")
//            //return
//        }
//        print("=== 2 ")
////        let authentication = user.authentication
//        let credential = FIRGoogleAuthProvider.credential(withIDToken: (authentication?.idToken)!, accessToken: (authentication?.accessToken)!)
//        // ...
//        
//        self.firebaseAuth(credential)
        
        
 //   }

}

