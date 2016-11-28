//
//  LoginVC.swift
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


class LoginVC: UIViewController, GIDSignInUIDelegate {
    
    private var authStateDidChangeListenerHandle: FIRAuthStateDidChangeListenerHandle!
    
    @IBOutlet weak var emailField: MyTextField!
    @IBOutlet weak var passwordField: MyTextField!

    
    override func viewDidLoad() {
        super.viewDidLoad()
 
    }
    
    override func viewWillAppear(_ animated: Bool) {
        print("==[LoginVC].viewWillAppear : \n")
        if FIRAuth.auth()?.currentUser != nil {
            dismiss(animated: true, completion: nil)
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        print("==[LoginVC].viewWillDisappear : \n")
    }
    
    
    func setAuthObservser(){
        
    }
    
    override func viewDidAppear(_ animated: Bool) {

    }

    @IBAction func fbButtonTapped(_ sender: Any) {
        
        let facebookLogin = FBSDKLoginManager()
        facebookLogin.logIn(withReadPermissions: ["email"], from: self) { (result, error) in
            if error != nil {
                print("=== [LoginVC].fbButtonTapped() : Unable to auth with Facebook === \(error) ")
            } else if result?.isCancelled == true {
                print("=== [LoginVC].fbButtonTapped() : User cancelled Facebook auth ")
            } else {
                print("=== [LoginVC].fbButtonTapped() : Successfully authenticated with Facebook ")
                let credential = FIRFacebookAuthProvider.credential(withAccessToken: FBSDKAccessToken.current().tokenString)
                
                self.firebaseAuth(credential)
            }
        }
    }
    
    @IBAction func googleButtonTapped(_ sender: Any) {
      //  sign(GIDSignIn!, didSignInFor: GIDGoogleUser!, withError: Error?)
      print(emailField.text!)
        
    }
    
    @IBAction func githubButtonTapped(_ sender: Any) {
    }
    
    
    func firebaseAuth(_ credential: FIRAuthCredential) {     
        FIRAuth.auth()?.signIn(with: credential, completion: { (gIdUser, error) in
            if error != nil {
                print("=== [LoginVC].firebaseAuth(FIRAuth.auth()?.signIn completion): Error! Unable to authenticate with Facebook account in Firebase - \(error) \n")
            } else {
                print("=== [LoginVC].firebaseAuth(FIRAuth.auth()?.signIn completion): Successfully authenticated with Facebook account in Firebase \n")
                if let gIdUser = gIdUser {
                    self.completeSignIn(id: gIdUser.uid, userData: ["provider": credential.provider])
                    print("==== [LoginVC].firebaseAuth(FIRAuth.auth()?.signIn completion): credential.provider] = \(credential.provider) \n")
                }
            }
        })
    }

    
    
    @IBAction func loginButtonTapped(_ sender: Any) {
        
        tryLoginWithEmail(email: emailField.text!, password: passwordField.text!) { firUser in
            
            if let firUser = firUser {
                print("=== [LoginVC].loginButtonTapped (tryLoginWithEmail completion):   tryLoginWithEmail: Successful -> Go to completeSignIn\n")
                self.completeSignIn(id: firUser.uid, userData: ["provider": firUser.providerID])
            } else {
                print("=== [LoginVC].loginButtonTapped(tryLoginWithEmail completion): ERROR (firUser is nil)\n")
            }
        }
        

    }
    
    func tryLoginWithEmail(email: String, password: String, completion: @escaping (_ firUser: FIRUser?) -> Void) {
        
        FIRAuth.auth()?.signIn(withEmail: email, password: password) { (firUser, error) in
            if error == nil {
                print("=== [LoginVC].tryLoginWithEmail (FIRAuth.auth()?.signIn copletion): User successfully authenticated with Email: \(firUser?.email)\n")
                if let firUser = firUser {
                    completion(firUser)
                    return
                } else {
                    
                }
                
            } else {
                
                print("=== [LoginVC].tryLoginWithEmail (FIRAuth.auth()?.signIn copletion): Error during authenticating with email/password: \(error.debugDescription)\n")
            }
            completion(nil)
        }
    }
    
    @IBAction func signInButtonTapped(_ sender: Any) {
       performSegue(withIdentifier: "segueLogInToUserVC", sender: nil)
        
    }
    
    
    func completeSignIn(id: String, userData: Dictionary<String, String>) {
        DataService.ds.createFirebaseDBUser(uid: id, userData: userData)
        if KeychainWrapper.standard.set(id, forKey: KEY_UID) {
            print("===[LoginVC].completeSignIn () : KeychainWrapper.standard.set() ")
            //performSegue(withIdentifier: "segueLogInToFeedVC", sender: nil /*User(userName: id)*/)
            dismiss(animated: true, completion: nil)
        } else {
            print("====[LoginVC].completeSignIn () : ERROR saving ID to keychain ")
        }
        
    }

    

    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {

        
        if segue.identifier == "segueLogInToUserVC" {
            //open UserProfileVC for adding new user
            if let userProfileVC = segue.destination as? UserVC {
                userProfileVC.openedFor = .create
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

