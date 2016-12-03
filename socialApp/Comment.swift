//
//  Comment.swift
//  socialApp
//
//  Created by Oleg Pavlichenkov on 02/12/2016.
//  Copyright © 2016 Oleg Pavlichenkov. All rights reserved.
//

import Foundation
import Firebase

class Comment {
    private var _commentKey: String!
    private var _caption: String!
    private var _postKey: String!
//    private var _postRef: FIRDatabaseReference!
    private var _authorKey: String!
//    private var _authorRef: FIRDatabaseReference!
    private var _authorName: String!
    private var _authorAvatarUrl: String!
    private var _dateOfCreate: Date!
    private var _dateOfUpdate: Date!    
//    private var _imageUrl: String!
//    private var _likes: Int!

    var commentKey: String? {
        get {
            return _commentKey
        } set {
            _commentKey = newValue
        }
    }
    
    var caption: String? {
        get {
            return _caption
        } set {
            _caption = newValue
        }
    }
    
    var authorKey: String {
        get {
            return _authorKey ?? ""
        } set {
            _authorKey = newValue
        }
        
    }
    
    var authorName: String? {
        get {
            return _authorName
        } set {
            _authorName = newValue
        }
    }
    
    var authorAvatarUrl: String? {
        get {
            return _authorAvatarUrl
        } set {
            _authorAvatarUrl = newValue
        }
    }
    
    var dateOfCreate: Date {
        get {
            return _dateOfCreate ?? Date(timeIntervalSince1970: 0)
        } set {
            _dateOfCreate = newValue
        }
    }
    
    var dateOfUpdate: Date {
        get {
            return _dateOfUpdate ?? Date(timeIntervalSince1970: 0)
        } set {
            _dateOfUpdate = newValue
        }
    }
    
    init() {
        self._commentKey = ""
    }
    
    init(commentKey: String, commentData: [String: Any]) {
        
        self._commentKey = commentKey
        
        if let caption = commentData["caption"] as? String {
            self._caption = caption
        }
        // postKey doesn't saves with creation of comment
        if let postKey = commentData["postKey"] as? String {
            self._postKey = postKey
        }
        
        if let authorKey = commentData["authorKey"] as? String {
            self._authorKey = authorKey
        }
        
        if let dateOfCreate = commentData["dateOfCreate"]  as? TimeInterval {
            self._dateOfCreate = Date(timeIntervalSince1970: dateOfCreate/1000)
        }
        
        if let dateOfUpdate = commentData["dateOfUpdate"]  as? TimeInterval {
            self._dateOfUpdate = Date(timeIntervalSince1970: dateOfUpdate/1000)
        }
        
    }



}
