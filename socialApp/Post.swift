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
    private var _dateOfCreate: Date!
    private var _dateOfUpdate: Date!
    
    var caption: String {
        return _caption
    }
    
    var imageUrl: String { get {
        return _imageUrl ?? ""
        
        } set {
            _imageUrl = newValue
        }
        
    }
    
    var likes: Int {
        return _likes ?? 0
    }
    
    var postKey: String {
        return _postKey ?? ""
    }
    
    var authorKey: String {
        return _authorKey ?? ""
    }
    
    var authorName: String {
        get {
            return _authorName ?? ""
        } set {
            _authorName = newValue
        }
    }
    
    var authorAvatarUrl: String {
        get {
            return _authorAvatarUrl ?? ""
        } set {
            _authorAvatarUrl = newValue
        }
    }
    
    var dateOfCreate: Date { get {
            return _dateOfCreate
        } set {
            _dateOfCreate = newValue
        }
    }

    var dateOfUpdate: Date { get {
        return _dateOfUpdate
        } set {
            _dateOfUpdate = newValue
        }
    }
    
    init() {
        self._likes = 0
    }
    
    init(caption: String, imageUrl: String, likes: Int) {
        // init for brand new post
        self._caption = caption
        self._imageUrl = imageUrl
        self._likes = likes
    }
    
    init(postKey: String, postData: [String : Any]) {
        
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
        
        if let dateOfCreate = postData["dateOfCreate"]  as? TimeInterval {
            self._dateOfCreate = Date(timeIntervalSince1970: dateOfCreate/1000)
        }
        
        if let dateOfUpdate = postData["dateOfUpdate"]  as? TimeInterval {
            self._dateOfUpdate = Date(timeIntervalSince1970: dateOfUpdate/1000)
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
