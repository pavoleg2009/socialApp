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

    static var imageCache: NSCache<NSString, UIImage> = NSCache()
    
    //DB references
    private var _REF_BASE = DB_BASE
    private var _REF_POSTS = DB_BASE.child("posts")
    private var _REF_USERS = DB_BASE.child("users")
    
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
