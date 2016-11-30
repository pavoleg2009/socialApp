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
    
    var openedFor: OpenedFor = .create
    var imagePicker: UIImagePickerController!
    var avatarSelectedOrChanged = false
    
    @IBOutlet weak var userVCCaptionLabel: UILabel!
    @IBOutlet weak var userAvatarImage: CircleView!
    @IBOutlet weak var userNameField: MyTextField!
    @IBOutlet weak var emailField: MyTextField!
    @IBOutlet weak var passwordField: MyTextField! 
    @IBOutlet weak var confirmPasswordField: MyTextField!
    @IBOutlet weak var saveButton: MyButton!
    @IBOutlet weak var deleteButton: MyButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setImagePicker()
        
        switch self.openedFor {
        case .edit: // if view opened for editing existing user (with any auth provider)
            CurrentUser.cu.readCurrentUserFromDatabase(){
                self.configureUserVCForEdit()
                self.loadUserAvatar()
            }
        default: // if view opened for adding user
            configureUserVCForCreate()
        }
    }
    
////////////////////////////////
// Creating New User
////////////////////////////////
    
    func configureUserVCForCreate() {
        userVCCaptionLabel.text = "New User"
        userNameField.text = ""
        emailField.text = ""
        passwordField.text = ""
        confirmPasswordField.text = ""
        
        saveButton.setTitle("Create User (Sign In)", for: [])
        saveButton.addTarget(self, action: #selector(UserVC.createUserTapped(_:)), for: .touchUpInside)
        
        deleteButton.isHidden = true
        userAvatarImage.image = UIImage(named: "default-avatar-catty")
    }
    
    func createUserTapped(_ sender: Any) {
        if isEnteredDataValidForNewUser() {
            createUserInFirebaseAuth(){
                let avatarImage = self.avatarSelectedOrChanged ? self.userAvatarImage.image : nil
                DataService.ds.createImageInStorage(image: avatarImage, ref: DataService.ds.REF_USER_AVARATS) {createdImageURL in
                    self.prepareUserDataForCreate(userAvatarUrl: createdImageURL) { (id, userData) in
                        self.completeSignIn(id: id, userData: userData)
                    }
                }
            }

        } else {
            print("===[UserVC].createUserTapped() : New user data is invalid. Please check User name, Email, Password and Confirm Password\n")
        }
    }
    
    func isEnteredDataValidForNewUser() -> Bool {
        // userName (not empty)
        // email (not empty & correct format & user not exist
        // password ( >= 8 characters, password = password confirm
        return userNameField.text != "" && emailField.text != "" && passwordField.text != ""
    }
    
    func createUserInFirebaseAuth(completion: @escaping () -> Void) {

        FIRAuth.auth()?.createUser(withEmail: emailField.text!, password: passwordField.text!, completion: { (user, error) in
            if error != nil {
                print("==[UserVC].createUserInFirebaseAuth() Unable to create user in Firebase Auth with email: \(error.debugDescription)")
                
                CurrentUser.cu.currentFIRUser = nil
            } else {
                if let user = user {
                    CurrentUser.cu.currentFIRUser = user // i think it's usefull becouse off FeedVC. currentUser observer?
                    print("==[UserVC].createUserInFirebaseAuth() : New user successfully created in Firebase \(user.email)\n")
                    CurrentUser.cu.writeFIRUserDataToCurrenDBUser()
                }
            }
            completion()
        })
    }
    
    func prepareUserDataForCreate(userAvatarUrl: String?, completion: @escaping(_ id: String, _ userData: Dictionary<String, Any>)-> Void){
        
        if let user = CurrentUser.cu.currentDBUser, user.provider != "" {

            var userData: [String : Any] = [
                "email" : user.email,
                "provider" : user.provider,
                "userName" : userNameField.text!
            ]
            
            if let url = userAvatarUrl, url != "" {
                userData["avatarUrl"] = url
            }
            
            if let userKey = user.userKey {
                completion(userKey, userData)
            } else {
                
            }
            
        } else {
            print("====[UserVC].cprepareUserDataForCreate:  ERROR preparing Data for new user in db :  \n")
        }
    }

//!! may be to rewrite? Why createFirebaseDBUser
    func completeSignIn(id: String, userData: Dictionary<String, Any>) {
        CurrentUser.cu.createFirebaseDBUser(uid: id, userData: userData)
        if KeychainWrapper.standard.set(id, forKey: KEY_UID) {
            self.dismiss(animated: true, completion: nil)
        } else {
            print("====[UserVC].completeSignIn():  ERROR saving ID to keychain \n")
        }
    }

////////////////////////////////
// Read User Data From Database
////////////////////////////////
      
    func configureUserVCForEdit() {
        
        userVCCaptionLabel.text = "Edit User"
        userNameField.text = CurrentUser.cu.currentDBUser.userName
        emailField.text = CurrentUser.cu.currentDBUser.email
        saveButton.setTitle("Save User", for: [])
        saveButton.addTarget(self, action: #selector(UserVC.saveUserTapped(_:)), for: .touchUpInside)
    }
    
    func loadUserAvatar() {
        
        if CurrentUser.cu.currentDBUser.avatarUrl != "" {
            DataService.ds.readImageFromStorage(imageUrl: CurrentUser.cu.currentDBUser.avatarUrl) { (image) in
                self.userAvatarImage.image = image
                return
            }
        } else {
            print("=== No user avatar URL assigned to user\n")
        }
    }

    
////////////////////////////////
// Update User Data in Database
////////////////////////////////

    func saveUserTapped(_ sender: Any) {
        // https://firebase.google.com/docs/auth/ios/manage-users - add email and password change
        if enteredDataIsValidForExistingUser() {
            if avatarSelectedOrChanged {
                tryToDeleteOldAvatar()
                DataService.ds.createImageInStorage(image: self.userAvatarImage.image, ref: DataService.ds.REF_USER_AVARATS) {savedImageUrl in
                    self.saveExistingUserToDatabase(userAvatarUrl: savedImageUrl)
                }
            } else {
                self.saveExistingUserToDatabase(userAvatarUrl: nil)
            }
        }
    }

    func enteredDataIsValidForExistingUser() -> Bool {
        // userName (not empty)
        // email (not empty & correct format & not used by other user
        // password ( >= 8 characters, password = password confirm
        return userNameField.text != ""
    }
    
    func tryToDeleteOldAvatar(){
        if CurrentUser.cu.currentDBUser.avatarUrl != "" {
            DataService.ds.deleteImageFromStorage(imageUrl: CurrentUser.cu.currentDBUser.avatarUrl)
        }
    }


    func saveExistingUserToDatabase(userAvatarUrl: String?){
        if let user = CurrentUser.cu.currentDBUser {
            // === create data for new user
            var userData = [
                "userName" : userNameField.text!,
            ]
            
            if let url = userAvatarUrl, url != "" {
                userData["avatarUrl"] = url
            }
            if let userKey = user.userKey, userKey != "" {
                self.completeSignIn(id: userKey, userData: userData)
            }
            
        }
    }

////////////////////////////////
//  Delete User
////////////////////////////////

    @IBAction func deleteButtonTapped(_ sender: MyButton) {
        print("==[UserVC].deleteButtonTapped")
    }
    
////////////////////////////////
//  Others
////////////////////////////////
 
    @IBAction func userImageTapped(_ sender: Any) {
        present(imagePicker, animated: true, completion: nil)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        if let image = info[UIImagePickerControllerEditedImage] as? UIImage {
            userAvatarImage.image = image
            avatarSelectedOrChanged = true
        } else {
            print("====[UserVC].imagePickerController..didFinishPickingMediaWithInfo: Invalid media selected\n")
        }
        imagePicker.dismiss(animated: true, completion: nil)
    }
    
    func setImagePicker() {
        imagePicker = UIImagePickerController()
        imagePicker.allowsEditing = true
        imagePicker.delegate = self
    }
    
    @IBAction func cancelButtonTapped(_ sender: Any) {
        self.dismiss(animated: true)
        
    }
    
    @IBAction func backButtonPressed(_ sender: Any) {
        dismiss(animated: true)
    }
}


