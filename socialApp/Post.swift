//
//  Post.swift
//  socialApp
//
//  Created by Oleg Pavlichenkov on 10/11/2016.
//  Copyright © 2016 Oleg Pavlichenkov. All rights reserved.
//

import Foundation
import Firebase

class Post {
    

    private var _caption: String!
    private var _imageUrl: String!
    private var _likes: Int!
    private var _postKey: String!
    private var _postRef: FIRDatabaseReference!
    private var _authorKey: String!
    private var _authorName: String!
    private var _authorAvatarUrl: String!
    
    var caption: String {
        return _caption
    }
    
    var imageUrl: String {
        return _imageUrl
    }
    
    var likes: Int {
        return _likes
    }
    
    var postKey: String {
        return _postKey
    }
    
    var authorKey: String {
        if _authorKey == nil {
            _authorKey = ""
        }
        return _authorKey
    }
    
    var authorName: String {
        get {
           if _authorName == nil {
            _authorName = ""
        }
        return _authorName 
        } set {
            _authorName = newValue
        }
        
    }
    
    var authorAvatarUrl: String {
        get {
            if _authorAvatarUrl == nil {
                _authorAvatarUrl = ""
            }
            return _authorAvatarUrl
        } set {
            _authorAvatarUrl = newValue
        }
        
    }
    
    init(caption: String, imageUrl: String, likes: Int) {
        
        self._caption = caption
        self._imageUrl = imageUrl
        self._likes = likes
    }
    
    init(postKey: String, postData: Dictionary<String, Any>) {
        
        self._postKey = postKey
        
        if let caption = postData["caption"] as? String {
            self._caption = caption
        }
        
        if let imageUrl = postData["imageUrl"] as? String {
            self._imageUrl = imageUrl
        }
        
        if let likes = postData["likes"]  as? Int {
            self._likes = likes
        }
        
        if let authorKey = postData["authorKey"]  as? String {
            self._authorKey = authorKey
        }
        _postRef = DataService.ds.REF_POSTS.child(_postKey)
        
    }
    
    func adjustLike(addLike: Bool) {
        
        if addLike {
            self._likes = self._likes + 1
        } else {
            self._likes = self._likes - 1
        }
        _postRef.child("likes").setValue(_likes)
    }
}
