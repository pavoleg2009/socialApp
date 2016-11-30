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
    var currentDBUser: User!
    var currentFIRUser: FIRUser!
    static var imageCache: NSCache<NSString, UIImage> = NSCache()
    
    //DB references
    private var _REF_BASE = DB_BASE
    private var _REF_POSTS = DB_BASE.child("posts")
    private var _REF_USERS = DB_BASE.child("users")
    private var _REF_USER_CURRENT: FIRDatabaseReference!
    
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
    
    
    var REF_USER_CURRENT_get_count = 0
    var REF_USER_CURRENT_set_count = 0
    
    var REF_USER_CURRENT: FIRDatabaseReference? {
        
        get {
            REF_USER_CURRENT_get_count += 1
            if _REF_USER_CURRENT != nil {
                return _REF_USER_CURRENT
                
            } else if let uid = KeychainWrapper.standard.string(forKey: KEY_UID) {
                
                print("====[DataService.ds].REF_USER_CURRENT: User read from KeyChain : \(REF_USER_CURRENT_get_count)\n")
                return REF_USERS.child(uid)
                
            } else {
                print("===[DataService.ds].REF_USER_CURRENT: ERROR: No uresId in currenUser and in KeyChain\n")
                //return FIRDatabaseReference()
                return nil
            }
            
        } set {
            REF_USER_CURRENT_set_count += 1
            _REF_USER_CURRENT = newValue
        }
        
        
        
        
        
        // looking for current user ID
        
        // 1. in local var currentDBUser: User!

//!! << Facebook login failed here
        
//        if let key = currentDBUser.userKey, key != "" {
//            print("====[DataService.ds].REF_USER_CURRENT: User read from Local currentDBUser.userKey \n")
//            return REF_USERS.child(key)
//        }
        // 2. in KeyChain
//        else
        
    }
    
////////////////////////////////////////////////
//  CRud users in Firbase Database
////////////////////////////////////////////////
    
    func createFirebaseDBUser(uid: String, userData: Dictionary<String, Any>) {
        
        REF_USERS.child(uid).updateChildValues(userData)

    }

    func writeFIRUserDataToCurrenDBUser(){
        // write
        
        if DataService.ds.currentDBUser == nil {
            DataService.ds.currentDBUser = User()
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
    
    
    // read user data from db/users/$uid/... for current autenticated user
    // and save it to currentDBUser variable
   
    func readCurrentUserFromDatabase(completion: @escaping ()-> Void){
        REF_USER_CURRENT?.observeSingleEvent(of: .value, with: { (snapshot) in
            
            if let _ = snapshot.value as? NSNull {
                print("====[.ds].readCurrentUserFromDatabase() : Error trying to get snapshor ffrom \\users. Snapshot is nil \n")
            } else {
                
                if let snapDict = snapshot.value as? [String : AnyObject]{
                    
                    if DataService.ds.currentDBUser == nil {
                        DataService.ds.currentDBUser = User()
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
        completion()
        
    }
    
////////////////////////////////////////////////
//  CRUD with Images at Firbase Storage
////////////////////////////////////////////////
    
    public func createImageInStorage(image: UIImage?, ref: FIRStorageReference, completion: @escaping (_ createdImageURL: String?) -> Void) {
        guard let image = image else {
            print("===[.ds].createImageInStorage() : No image (nil) passed to save")
            completion(nil)
            return
        }
        
        if let imageDada = UIImageJPEGRepresentation(image, 0.2) {
            let imageUid = NSUUID().uuidString
            let metadata = FIRStorageMetadata()
            metadata.contentType = "image/jpeg"
            
            ref.child(imageUid).put(imageDada, metadata: metadata) { (metadata, error) in
                if error != nil {
                    print("====[ds.].saveImageToStorage() :  Unable to upload image to Firebase Storage: \(error.debugDescription) ")
                    completion(nil)
                    return
                } else {
                    let downloadURL = metadata?.downloadURL()?.absoluteString
                    completion(downloadURL)
                    return
                }
                
            }
        } else {
            completion(nil)
            return
        }
    }

    public func readImageFromStorage(imageUrl: String?, completion: @escaping (_ loadedImage: UIImage?) -> Void) {
        
        if let url = imageUrl, url != "" {
            // check image in cache
            if let image = DataService.imageCache.object(forKey: url as NSString) {
//                print("==[.ds].readImageFromStorage: Image loaded from cache\n")
                completion(image)
                return
            } else {
            // if no in cache - try load from FireStorage
                let ref = FIRStorage.storage().reference(forURL: url)
                ref.data(withMaxSize: 2 * 1024 * 1024 /* 2 Megabytes*/, completion: { (data, error) in
                    if error != nil {
                        print("===[.ds].readImageFromStorage: Unable to download image from Firebase storage: \(error.debugDescription) \n")
                        completion(nil)
                        return
                    } else {
//                        print("==[.ds].readImageFromStorage: Image downloaded from Firebase storage\n" )
                        if let imgData = data {
                            if let img = UIImage(data: imgData) {

                                DataService.imageCache.setObject(img, forKey: url as NSString)
                                completion(img)
                                return
                            } else {
                                print("====[.ds].readImageFromStorage: Can't cast Object in cache to UIImage \n" )
                            }
                        } else {
                            print("====[.ds].readImageFromStorage: No data in specified url: <\(url)> \n" )
                            completion(nil)
                            return
                        }
                    }
                })
            }
            
        } else {
            completion(nil)
        }
    }
    
    public func deleteImageFromStorage(imageUrl: String?) {
        if let url = imageUrl, url != "" {
            let ref = FIRStorage.storage().reference(forURL: url)
            ref.delete { (error) -> Void in
                if (error != nil) {
                    // Uh-oh, an error occurred!
                    print("====[.ds].deleteImageFromStorage:  ERROR on Firebase side:  \(error.debugDescription)\n")
                } else {
                    // File deleted successfully
                    print("===[.ds].deleteImageFromStorage:  File deleted successfully\n")
                }
            }
        } else {
            print("====[.ds].deleteImageFromStorage:  ERROR: URL to delete is empty: \(imageUrl!)\n")
        }
    }

}
