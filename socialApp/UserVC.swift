//
//  UserVC.swift
//  socialApp
//
//  Created by Oleg Pavlichenkov on 11/11/2016.
//  Copyright © 2016 Oleg Pavlichenkov. All rights reserved.
//

import UIKit
import Firebase

class UserVC: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    var user: User!
    var openedFor: OpenedFor = .insert
    var imagePicker: UIImagePickerController!
    var imageSelected = false
    
    let refreshAlert = UIAlertController(title: "Refresh", message: "All data will be lost.", preferredStyle: UIAlertControllerStyle.alert)
    
    @IBOutlet weak var openForLabel: UILabel!
    @IBOutlet weak var openForModeLabel: UILabel!
    
    @IBOutlet weak var userImage: UIImageView!
    @IBOutlet weak var emailField: MyTextField!
    @IBOutlet weak var passwordField: MyTextField! 
    @IBOutlet weak var confirmPasswordField: MyTextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //configureAlerts()
        imagePicker = UIImagePickerController()
        imagePicker.allowsEditing = true
        imagePicker.delegate = self
        
        switch self.openedFor {
        case .edit:
            if let user = user {
                configureViewForEdit(user: user)
            } else {
                configureViewForEdit(user: User(userName: "Vanya"))
            }
            
        default:
            configureViewForInsert()
        }
        
        
    }


    @IBAction func backButtonPressed(_ sender: Any) {
        dismiss(animated: true)
    }
    
    func configureViewForInsert() {
        openForLabel.text = "Insert"
        
    }
    
    func configureViewForEdit(user: User) {
        openForLabel.text = "Edit"
    }
    

    @IBAction func signInButtonTapped(_ sender: Any) {
        
        if let email = emailField.text , let password = passwordField.text {
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
                                print("=== Unable to authenticate in Firebase with email: \(error.debugDescription)")
                            } else {
                                
                                if let gIdUser = gIdUser {
                                    let userData = ["provider": gIdUser.providerID]
                                    print("=== User created with Email: \(email) and provider \(gIdUser.providerID)")
                                    // - send to SignInVC
                                    
                                    self.performSegue(withIdentifier: "segueUserToLogInVC", sender: nil)
                                    //   self.completeSignIn(id: user.uid, userData: userData)
                                }
                            }
                        })

                    }
                    
                }
            })
        }
    }


    
    @IBAction func testButtonPressed(_ sender: Any) {
        

        
       // present(refreshAlert, animated: true, completion: nil)
    }
    
    func configureAlerts() {
        refreshAlert.addAction(UIAlertAction(title: "Ok", style: .default, handler: { (action: UIAlertAction!) in
            print("Handle Ok logic here")
        }))
        
        refreshAlert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { (action: UIAlertAction!) in
            print("Handle Cancel Logic here")
        }))
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
       //
        
        if segue.identifier == "segueUserToLogInVC" {
            if let logInVC = segue.destination as? LogInVC {
                //LogInVC
            }
        }
    }
    
    @IBAction func userImageTapped(_ sender: Any) {
        
        present(imagePicker, animated: true, completion: nil)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        if let image = info[UIImagePickerControllerEditedImage] as? UIImage {
            userImage.image = image
            imageSelected = true
        } else {
            print("Invalid media selected")
        }
        imagePicker.dismiss(animated: true, completion: nil)
    }
    
}
