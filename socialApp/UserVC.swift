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
    var avataSelectedOrChanged = false
    static var imageCache2: NSCache<NSString, UIImage> = NSCache()
    
    var createdUser: FIRUser!
    
    @IBOutlet weak var userAvatarImage: CircleView!
    @IBOutlet weak var userNameField: MyTextField!
    @IBOutlet weak var emailField: MyTextField!
    @IBOutlet weak var passwordField: MyTextField! 
    @IBOutlet weak var confirmPasswordField: MyTextField!
    @IBOutlet weak var saveButton: MyButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setImagePicker()
        currentUser = User()
        
        switch self.openedFor {
        case .edit: // if view opened for editing existing user (with any auth provider)
            loadCurrentUserData(){
                self.configureUserViewForEdit()
                self.loadUserAvatar() {}
            }
            
        default: // if view opened for adding user
            saveButton.setTitle("Sign In", for: [])
            saveButton.addTarget(self, action: #selector(UserVC.signInTapped(_:)), for: .touchUpInside)
        }
        
    
    }
//////////////////////////////////////////////////////////////
// Loading User Data From Database
//////////////////////////////////////////////////////////////
    
    func loadCurrentUserData(completion: @escaping() -> Void) {
        
        currentUser.userKey = DataService.ds.ID_USER_CURRENT
        
        DataService.ds.REF_USER_CURRENT.observeSingleEvent(of: .value, with: { (snapshot) in
  
            if let _ = snapshot.value as? NSNull {
                print("=== User nof found in Users (REF_USER_CURRENT) - (snapshot = nil)")
            } else {

                let snapDict = snapshot.value as? [String : AnyObject]

                if let userName = snapDict?["userName"] as? String {
                    self.currentUser.userName = userName
                }
                
                if let email = snapDict?["email"] as? String {
                    self.currentUser.email = email
                }
                
                if let provider = snapDict?["provider"] as? String {
                    self.currentUser.provider = provider
                }
                
                if let avatarUrl = snapDict?["avatarUrl"] as? String  {
                    self.currentUser.avatarUrl = avatarUrl
                }
            }
            
            completion()
        })
    }
    
    func configureUserViewForEdit() {
        userNameField.text = currentUser.userName
        emailField.text = currentUser.email
        saveButton.setTitle("Save", for: [])
        saveButton.addTarget(self, action: #selector(UserVC.saveUserTapped(_:)), for: .touchUpInside)
    }
    
    func loadUserAvatar(completion: @escaping() -> Void) {
        if currentUser.avatarUrl != "" {
            let ref = FIRStorage.storage().reference(forURL: currentUser.avatarUrl)
            
            ref.data(withMaxSize: 2 * 1024 * 1024 /* 2 Megabytes*/, completion: { (data, error) in
                if error != nil {
                    print(" === Unable to download image from Firebase Data Storage: \(error.debugDescription) ")
                } else {
                    if let imgData = data {
                        if let img = UIImage(data: imgData) {
                            self.userAvatarImage.image = img
                            UserVC.imageCache2.setObject(img, forKey: self.currentUser.avatarUrl as NSString)
                        }
                    }
                }

            })
        } else {
            print("=== No user avatar URL assigned to user\n")
        }
        completion()
    }

//////////////////////////////////////////////////////////////
// Creating New User
//////////////////////////////////////////////////////////////
    
    @IBAction func signInTapped(_ sender: Any) {

        if isEnteredDataValidForNewUser() {
            createUserInFirebaseAuth(){
                self.saveAvatarToStorage(){
                    self.saveNewUserToDatabase()
                    
                }
            }
        }
        
    }
    
    func isEnteredDataValidForNewUser() -> Bool {
        // userName (not empty)
        // email (not empty & correct format & user not exist
        // password ( >= 8 characters, password = password confirm
        return true
    }
    
    func createUserInFirebaseAuth(completion: @escaping () -> Void) {
        FIRAuth.auth()?.createUser(withEmail: emailField.text!, password: passwordField.text!, completion: { (user, error) in
            if error != nil {
                print("=== Unable to create user in Firebase Auth with email: \(error.debugDescription)")
                self.createdUser = nil
            } else {
                self.createdUser = user
                self.createdUserToCurrentUser()
            }
            completion()
        })
        
    }
    
    func createdUserToCurrentUser(){
        currentUser.userKey = createdUser.uid
        currentUser.provider = createdUser.providerID
    }
    
    func saveAvatarToStorage(completion: @escaping () -> Void) {
        guard let image = userAvatarImage.image, avataSelectedOrChanged == true else {
            print(" === Image must be selected ")
            completion()
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
                    self.currentUser.avatarUrl = downloadURL!
                }
            completion()
            }
        } else {
            completion()
        }
        
    }
    
    func saveNewUserToDatabase(){
        if let user = currentUser {
            // === create data for new user
            let userData = [
                "email": emailField.text!,
                "provider": user.provider,
                "userName" : userNameField.text!,
                "avatarUrl" : user.avatarUrl
            ]
            
            self.completeSignIn(id: user.userKey, userData: userData)

        }

    }

    func completeSignIn(id: String, userData: Dictionary<String, String>) {
        
        DataService.ds.createFirebaseDBUser(uid: id, userData: userData)
        if KeychainWrapper.standard.set(id, forKey: KEY_UID) {
            self.dismiss(animated: true, completion: nil)
        } else {
            print(" === ERROR saving ID to keychain ")
        }
        
    }
    
//////////////////////////////////////////////////////////////
// Saving Changer User Info Database
//////////////////////////////////////////////////////////////

    func saveUserTapped(_ sender: Any) {
        // https://firebase.google.com/docs/auth/ios/manage-users - add email and password change
        if isEnteredDataValidForExistingUser() {
            
            self.saveAvatarToStorage(){  // also remove old avatar file
                self.saveExistingUserToDatabase()
                
            }
        }
    }
    
    func isEnteredDataValidForExistingUser() -> Bool {
        // userName (not empty)
        // email (not empty & correct format & not used by other user
        // password ( >= 8 characters, password = password confirm
        return true
    }

    func saveExistingUserToDatabase(){
        if let user = currentUser {
            // === create data for new user
            let userData = [
                "userName" : userNameField.text!,
                "avatarUrl" : user.avatarUrl
            ]
            
            self.completeSignIn(id: user.userKey, userData: userData)
        }
    }
    
//////////////////////////////////////////////////////////////
//  Others
//////////////////////////////////////////////////////////////


   
    @IBAction func userImageTapped(_ sender: Any) {
        
        present(imagePicker, animated: true, completion: nil)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        if let image = info[UIImagePickerControllerEditedImage] as? UIImage {
            userAvatarImage.image = image
            avataSelectedOrChanged = true
        } else {
            print("Invalid media selected")
        }
        imagePicker.dismiss(animated: true, completion: nil)
    }

    @IBAction func cancelButtonTapped(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
        
    }
    
    func setImagePicker() {
        imagePicker = UIImagePickerController()
        imagePicker.allowsEditing = true
        imagePicker.delegate = self
    }

    @IBAction func backButtonPressed(_ sender: Any) {
        dismiss(animated: true)
    }
}



//            if let email = emailField.text , let password = passwordField.text, let userName = userNameField.text {
//                FIRAuth.auth()?.fetchProviders(forEmail: email, completion: { (providers, error) in
//                    if error != nil {
//                        print("=== Error fetching auth providers for email: \(email) ====: \(error.debugDescription)")
//                    } else {
//                        if providers != nil {
//                            print("=== Email already used for : \(email): ")
//                            for i in 0..<providers!.count {
//                                print("=== Provider #\(i): \(providers![i])")
//                            }
//                        } else {
//                            // providers == nil  => no such email in database - ADD NEW USER
//                        }
//
//                    }
//                })
//            }


