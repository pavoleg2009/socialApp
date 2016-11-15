//
//  DataService.swift
//  socialApp
//
//  Created by Oleg Pavlichenkov on 10/11/2016.
//  Copyright © 2016 Oleg Pavlichenkov. All rights reserved.
//

import Foundation
import Firebase
import SwiftKeychainWrapper

let DB_BASE = FIRDatabase.database().reference()
let STORAGE_BASE = FIRStorage.storage().reference()

class DataService {
    
    static let ds = DataService() // creates a singletone
    
    //DB references
    private var _REF_BASE = DB_BASE
    private var _REF_POSTS = DB_BASE.child("posts")
    private var _REF_USERS = DB_BASE.child("users")
    private var _ID_USER_CURRENT: String!
    
    // Storage references
    private var _REF_POST_IMAGES = STORAGE_BASE.child("post-pics")
    private var _REF_USER_AVATARS = STORAGE_BASE.child("avatars")
    
    var REF_BASE: FIRDatabaseReference {
        return _REF_BASE
    }
    
    var REF_POSTS: FIRDatabaseReference {
        return _REF_POSTS
    }
    
    var REF_USERS: FIRDatabaseReference {
        return _REF_USERS
    }
    
    var REF_POST_IMAGES: FIRStorageReference {
        return _REF_POST_IMAGES
    }
    
    var REF_USER_AVARATS: FIRStorageReference {
        return _REF_USER_AVATARS
    }
    
    var REF_USER_CURRENT: FIRDatabaseReference {
        
        if let uid = KeychainWrapper.standard.string(forKey: KEY_UID) {
            let user = REF_USERS.child(uid)
            //print(" === user \(user) ")
            return user

        } else {
            print(" === No such record in KeyChain ")
            return FIRDatabaseReference()
        }
    }
    
    var ID_USER_CURRENT: String {
        get {
            if let uid = FIRAuth.auth()?.currentUser?.uid {
                _ID_USER_CURRENT = uid
            } else {
                _ID_USER_CURRENT = ""
            }

            return _ID_USER_CURRENT
            
        } set {
            _ID_USER_CURRENT = newValue
        }
    }
    
    var REF_AVATAR_DEFAULT: String {
        return ""
    }
    
    func createFirebaseDBUser(uid: String, userData: Dictionary<String, String>) {
        
        REF_USERS.child(uid).updateChildValues(userData)
        //REF_USERS.child(uid)
    }
    
}
