//
//  CurrentUser.swift
//  socialApp
//
//  Created by Oleg Pavlichenkov on 30/11/2016.
//  Copyright © 2016 Oleg Pavlichenkov. All rights reserved.
//

// Sungleton fof all data about current user

import Foundation
import Firebase
import SwiftKeychainWrapper

class CurrentUser {
    static let cu = CurrentUser()
    
    var currentDBUser: User!
    var currentFIRUser: FIRUser!
    
    private var _REF_USER_CURRENT: FIRDatabaseReference!
    
    var REF_USER_CURRENT_get_count = 0
    var REF_USER_CURRENT_set_count = 0
    
    var REF_USER_CURRENT: FIRDatabaseReference? {
        
        get {
            REF_USER_CURRENT_get_count += 1
            if _REF_USER_CURRENT != nil {
                return _REF_USER_CURRENT
                
            } else if let uid = KeychainWrapper.standard.string(forKey: KEY_UID) {
                
                print("====[DataService.ds].REF_USER_CURRENT: User read from KeyChain : \(REF_USER_CURRENT_get_count)\n")
                return DataService.ds.REF_USERS.child(uid)
                
            } else {
                print("===[DataService.ds].REF_USER_CURRENT: ERROR: No uresId in currenUser and in KeyChain\n")
                //return FIRDatabaseReference()
                return nil
            }
            
        } set {
            REF_USER_CURRENT_set_count += 1
            _REF_USER_CURRENT = newValue
        }

    }
    
        var uid: String? {
            if (currentFIRUser) != nil {
                return currentFIRUser.uid
            } else {
                return nil
            }
            
        }
    
    
////////////////////////////////////////////////
//  CRud users in Firbase Database
////////////////////////////////////////////////
    
    func createFirebaseDBUser(uid: String, userData: Dictionary<String, Any>) {
        
        DataService.ds.REF_USERS.child(uid).updateChildValues(userData)
        
    }
    
    
    // read user data from db/users/$uid/... for current autenticated user
    // and save it to currentDBUser variable

    
    func readCurrentUserFromDatabase(completion: @escaping ()-> Void){
        
        CurrentUser.cu.REF_USER_CURRENT?.observeSingleEvent(of: .value, with: { (snapshot) in

            if let _ = snapshot.value as? NSNull {
                print("====[.ds].readCurrentUserFromDatabase() : Error trying to get snapshor from \\users. Snapshot is nil \n")
            } else {
                
                if let snapDict = snapshot.value as? [String : AnyObject]{
                    
                    if self.currentDBUser == nil {
                        self.currentDBUser = User()
                    }
                    
                    if let userName = snapDict["userName"] as? String {
                        self.currentDBUser.userName = userName
                    }
                    
                    if let email = snapDict["email"] as? String {
                        self.currentDBUser.email = email
                    }
                    
                    if let provider = snapDict["provider"] as? String {
                        self.currentDBUser.provider = provider
                    }
                    
                    if let str = snapDict["avatarUrl"] as? String {
                        self.currentDBUser.avatarUrl = str
                    }
                }
            }
            completion()
        })
    }
    
    func writeFIRUserDataToCurrenDBUser(){
        // write
        
        if currentDBUser == nil {
            currentDBUser = User()
        }
        
        currentDBUser.userKey = currentFIRUser.uid
        currentDBUser.provider = currentFIRUser.providerID
        
        if let email = currentFIRUser.email {
            currentDBUser.email = email
        }
        
        //      may be add this to user data
        //        public var displayName: String? { get }
        //        public var photoURL: URL? { get }
        
    }
}
