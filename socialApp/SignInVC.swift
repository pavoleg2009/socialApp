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

class SignInVC: UIViewController {

    @IBOutlet weak var emailText: MyTextField!
    @IBOutlet weak var passwordText: MyTextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        //if id present in keychain
    
    }
    
    override func viewDidAppear(_ animated: Bool) {
        if let retrievedString: String = KeychainWrapper.standard.string(forKey: KEY_UID) {
            print("=== Seage to FeedVC with retrievedString = \(retrievedString)")
            performSegue(withIdentifier: "goToFeedVC", sender: User(userName:retrievedString))
            
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    @IBAction func fbButtonTapped(_ sender: Any) {
        
        let facebookLogin = FBSDKLoginManager()
        facebookLogin.logIn(withReadPermissions: ["email"], from: self) { (result, error) in
            if error != nil {
                print("=== Unable to auth with Facebook === \(error)")
            } else if result?.isCancelled == true {
                print("=== User cancelled Facebook auth")
            } else {
                print("=== Successfully authenticated with Facebook")
                let credential = FIRFacebookAuthProvider.credential(withAccessToken: FBSDKAccessToken.current().tokenString)
                
                self.firebaseAuth(credential)
            }
        }
    }
    
    @IBAction func googleButtonTapped(_ sender: Any) {
        
        
    }
    
    @IBAction func githubButtonTapped(_ sender: Any) {
    }
    
    
    func firebaseAuth(_ credential: FIRAuthCredential) {
        FIRAuth.auth()?.signIn(with: credential, completion: { (user, error) in
            if error != nil {
                print("=== Unable to authenticate with Firebase - \(error)")
            } else {
                print("=== Successfully authenticated with Firebase")
                if let user = user {
                    self.completeSignIn(id: user.uid)
                }
                
            }
        })
    }

    @IBAction func signInTapped(_ sender: Any) {
        
        if let email = emailText.text, let pwd = passwordText.text {
            FIRAuth.auth()?.signIn(withEmail: email, password: pwd, completion: { (user, error) in
                if error == nil {
                    print("=== User Successfully authenticated with Email")
                    if let user = user {
                        self.completeSignIn(id: user.uid)
                    }
                    
                } else {
                    FIRAuth.auth()?.createUser(withEmail: email, password: pwd, completion: { (user, error) in
                        if error != nil {
                            print("=== Unable to authenticate in Firebase with email")
                        } else {
                            print("=== Successfully with Firebase")
                            if let user = user {
                                self.completeSignIn(id: user.uid)
                            }
                        }
                    })
                }
            })
        }
    }
    
    func completeSignIn(id: String) {
        if KeychainWrapper.standard.set(id, forKey: KEY_UID) {
            print("=== ID Saved to keychain")
            performSegue(withIdentifier: "goToFeedVC", sender: User(userName:id))
        } else {
            print("=== ERROR saving ID to keychain")
        }
        
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "goToFeedVC" {
            if let feedVC = segue.destination as? FeedVC {
                if let user = sender as? User {
                    feedVC.currentUser = user
                }
            }
        }
    }
    

}

