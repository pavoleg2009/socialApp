//
//  UserVC.swift
//  socialApp
//
//  Created by Oleg Pavlichenkov on 11/11/2016.
//  Copyright © 2016 Oleg Pavlichenkov. All rights reserved.
//

import UIKit
import Firebase
import SwiftKeychainWrapper

class UserVC: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    var currentUser: User!
    var openedFor: OpenedFor = .insert
    var imagePicker: UIImagePickerController!
    static var imageCache2: NSCache<NSString, UIImage> = NSCache()
    var imageSelectedOrChanged = false
    
    let refreshAlert = UIAlertController(title: "Refresh", message: "All data will be lost.", preferredStyle: UIAlertControllerStyle.alert)
    
    @IBOutlet weak var openForLabel: UILabel!
    @IBOutlet weak var openForModeLabel: UILabel!
    
    @IBOutlet weak var userImage: UIImageView!
    
    @IBOutlet weak var userNameField: MyTextField!
    @IBOutlet weak var emailField: MyTextField!
    @IBOutlet weak var passwordField: MyTextField! 
    @IBOutlet weak var confirmPasswordField: MyTextField!
    
    
    @IBOutlet weak var saveButton: MyButton!
    override func viewDidLoad() {
        super.viewDidLoad()
        
        imagePicker = UIImagePickerController()
        imagePicker.allowsEditing = true
        imagePicker.delegate = self
        
        loadCurrentUserData()
        
      
    }

    func loadCurrentUserData() {
        DataService.ds.REF_USER_CURRENT.observeSingleEvent(of: .value, with: { (snapshot) in
            
            self.currentUser = User()
            
            if let _ = snapshot.value as? NSNull {
                print("=== REF_USER_CURRENT - snapshot not found")
            } else {
                //self.userEmailLabel.text =
                
                let snapDict = snapshot.value as? [String : AnyObject]
                
                if let userName = snapDict?["userName"] as? String {
                    //print(" === email = \(userName) \n")
                    self.currentUser.userName = userName
                    self.userNameField.text = userName
                }
                
                if let email = snapDict?["email"] as? String {
                    //print(" === email = \(email) \n")
                    self.currentUser.email = email
                    self.emailField.text = email
                }
                //                if let provider = snapDict?["provider"] as? String {
                //                    //print(" === provider = \(provider) \n")
                //                }
                
                //load image
                if let avatarUrl = snapDict?["avatarUrl"] as? String  {
                    
                    let ref = FIRStorage.storage().reference(forURL: avatarUrl)
                    ref.data(withMaxSize: 2 * 1024 * 1024 /* 2 Megabytes*/, completion: { (data, error) in
                        if error != nil {
                            print(" === Unable to download image from Firebase storage: \(error.debugDescription) ")
                        } else {
                            print(" === Image downloaded from Firebase storage" )
                            if let imgData = data {
                                if let img = UIImage(data: imgData) {
                                    self.userImage.image = img
                                    UserVC.imageCache2.setObject(img, forKey: avatarUrl as NSString)
                                }
                            }
                        }
                    })
                }
                
            }
            
            switch self.openedFor {
            case .edit:
                
                if let user = self.currentUser { // где курент юзер долджен сконфигуриться?
                    self.configureViewForEdit(user: user)
                } else {
                    print("=== No user for edit")
                }
                
            default:
                self.configureViewForInsert()
            }
            
        })
    }
    
    
    @IBAction func backButtonPressed(_ sender: Any) {
        dismiss(animated: true)
    }
    
    func configureViewForInsert() {
        openForLabel.text = "Insert"
        self.saveButton.setTitle("Sign In", for: [])
        
    }
    
    func configureViewForEdit(user: User) {
        openForLabel.text = "Edit"
        self.saveButton.setTitle("Save", for: [])
    }
    

    @IBAction func signInButtonTapped(_ sender: Any) {
        
        if self.openedFor == .insert {
            
            // Check user data entered for New User
                // userName (not empty)
                // email (not empty & correct format & user not exist
                // password ( >= 8 characters, password = password confirm
            
            // If userName - ok && email - ok && password - ok ( radyToSave) =>
            
            //Save New user
                // Create Auth User, if ok, get provider goto next
                // If avatar selected - Save avatar to sorage, get link
        
            if let email = emailField.text , let password = passwordField.text, let userName = userNameField.text {
                FIRAuth.auth()?.fetchProviders(forEmail: email, completion: { (providers, error) in
                    if error != nil {
                        print("=== Error fetching auth providers for email: \(email) ====: \(error.debugDescription)")
                    } else {
                        
                        if providers != nil {
                            print("=== Email already used for : \(email): ")
                            for i in 0..<providers!.count {
                                print("=== Provider #\(i): \(providers![i])")
                            }
                        } else {
                            // providers == nil  => no such email in database - ADD NEW USER
                            FIRAuth.auth()?.createUser(withEmail: email, password: password, completion: { (gIdUser, error) in
                                if error != nil {
                                    print("=== Unable to create user in Firebase with email: \(error.debugDescription)")
                                } else {
                                    
                                    // === save avatar
                                    
                                    self.saveAvatarToStorage(temp: "", completion: { (success, avatarUrl) in
                                        
                                        if let gIdUser = gIdUser {
                                            // === create data for new user
                                            let userData = [
                                                "email": email,
                                                "provider": gIdUser.providerID,
                                                "userName" : userName,
                                                "avatarUrl" : avatarUrl!
                                            ]
                                            
                                            self.completeSignIn(id: gIdUser.uid, userData: userData)
                                            print("=== User created with Email: \(email) and provider \(gIdUser.providerID)")
                                        }

                                    })
                                    
                                    
                                                                    }
                            })

                        }
                        
                    }
                })
            }
        } else if self.openedFor == .edit {
            
            // if email changed
            // https://firebase.google.com/docs/auth/ios/manage-users
            
            // if password changed
            // 
            
            // update User (not Auth)
            
            var userData = [
            //    "email": email,
            //    "provider": gIdUser.providerID,
                "userName" : userNameField.text
                
            ]
            
            if imageSelectedOrChanged {
                // remove old image from storage
                // add new image to storage, return ref
                print(" ===== 1")
                
                self.saveAvatarToStorage(temp: "", completion: { (success, avatarUrl) in
                    print(" ===== 2")
                    userData["avatarUrl"] = avatarUrl
                    print(" ===== 3")
                
                
                })
                
                print(" ===== 4")
                
                // add new image ref to userData
             
            }
            
            print(" ===== 5")
            DataService.ds.REF_USER_CURRENT.updateChildValues(userData, withCompletionBlock: { (error, FIRDatabaseReference) in
                print(" ===== 6")
                print("==== currens user updated")
                self.dismiss(animated: true, completion: nil)
            })
            
            
        }
        
        
        // saving image to database
        
//        guard let image = userImage.image, imageSelectedOrChanged == true else {
//            print(" === Image must be selected ")
//            return
//        }
        
//        if let imageDada = UIImageJPEGRepresentation(image, 0.2) {
//            
//            let imageUid = NSUUID().uuidString
//            let metadata = FIRStorageMetadata()
//            metadata.contentType = "image/jpeg"
//            
//            DataService.ds.REF_USER_AVARATS.child(imageUid).put(imageDada, metadata: metadata) { (metadata, error) in
//                if error != nil {
//                    print(" === Unable to upload image to Firebase Storage: \(error.debugDescription) ")
//                } else {
//                    
//                    let downloadURL = metadata?.downloadURL()?.absoluteString
//                    print(" === Successfully upload image to Firebase Storage with URL: \(downloadURL) ")
//                    if let url = downloadURL {
//                        //self.savePostToFirebase(imageUrl: url)
//                    } else {
//                        print(" === Image URL is empty ")
//                    }
//                }
//            }
//        }
        // End of saving image to database
    }

    func saveAvatarToStorage(temp: String, completion: @escaping (_ success: Bool, _ avatarUrl : String?) -> Void) {
        guard let image = userImage.image, imageSelectedOrChanged == true else {
            print(" === Image must be selected ")
            return
        }
        
        if let imageDada = UIImageJPEGRepresentation(image, 0.2) {
            
            let imageUid = NSUUID().uuidString
            let metadata = FIRStorageMetadata()
            metadata.contentType = "image/jpeg"
            
            DataService.ds.REF_USER_AVARATS.child(imageUid).put(imageDada, metadata: metadata) { (metadata, error) in
                if error != nil {
                    print(" === Unable to upload image to Firebase Storage: \(error.debugDescription) ")
                } else {
                    
                    let downloadURL = metadata?.downloadURL()?.absoluteString
                    print(" === Successfully upload image to Firebase Storage with URL: \(downloadURL) ")
                    if let url = downloadURL {
                        completion(true, url)
                        //self.savePostToFirebase(imageUrl: url)
                    } else {
                        print(" === Image URL is empty ")
                        completion(false, "")
                        
                    }
                }
            }
        }
        // End of saving image to database
        
    }
    
    func completeSignIn(id: String, userData: Dictionary<String, String>) {
        DataService.ds.createFirebaseDBUser(uid: id, userData: userData)
        if KeychainWrapper.standard.set(id, forKey: KEY_UID) {
            
            //go to FeedVC
            //performSegue(withIdentifier: "segueUserToFeedVC", sender: nil /*User(userName: id)*/)
            self.dismiss(animated: true, completion: nil)
        } else {
            print(" === ERROR saving ID to keychain ")
        }
        
    }
    

//    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
       //
        
//        if segue.identifier == "segueUserToLogInVC" {
//            if let logInVC = segue.destination as? LogInVC {
                //LogInVC
//            }
//        }
//        if segue.identifier == "segueUserToFeedVC" {
//            if let logInVC = segue.destination as? LogInVC {
                //LogInVC
//            }
//        }
//    }
    
    @IBAction func userImageTapped(_ sender: Any) {
        
        present(imagePicker, animated: true, completion: nil)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        if let image = info[UIImagePickerControllerEditedImage] as? UIImage {
            userImage.image = image
            imageSelectedOrChanged = true
        } else {
            print("Invalid media selected")
        }
        imagePicker.dismiss(animated: true, completion: nil)
    }

    @IBAction func cancelButtonTapped(_ sender: Any) {
        
        self.dismiss(animated: true, completion: nil)
        
//        DataService.ds.REF_USER_CURRENT.observeSingleEvent(of: .value, with: { (snapshot) in
//            
//            if let _ = snapshot.value as? NSNull {
//                print("=== REF_USER_CURRENT - snapshot not founs")
//            } else {
//                //self.userEmailLabel.text =
//                let snapDict = snapshot.value as? [String : AnyObject]
        
//                if let email = snapDict?["email"] as? String {
//                    print(" === email = \(email) \n")
//                }
//                if let provider = snapDict?["provider"] as? String {
//                    print(" === provider = \(provider) \n")
//                }
                
//            }
 //       })
        
        
    //
        
    }
    
//===========================================================
// UNSED
//===========================================================
    func configureAlerts() {
        refreshAlert.addAction(UIAlertAction(title: "Ok", style: .default, handler: { (action: UIAlertAction!) in
            print("Handle Ok logic here")
        }))
        
        refreshAlert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { (action: UIAlertAction!) in
            print("Handle Cancel Logic here")
        }))
    }
//===========================================================
}






