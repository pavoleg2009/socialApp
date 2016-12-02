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
    private var _commentText: String!
    private var _postKey: String!
//    private var _postRef: FIRDatabaseReference!
    private var _authorKey: String!
//    private var _authorRef: FIRDatabaseReference!
//    private var _authorName: String!
//    private var _authorAvatarUrl: String!
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
    
    var commentText: String? {
        get {
            return _commentText
        } set {
            _commentText = newValue
        }
    }
    
    var dateOfCreate: Date { get {
        return _dateOfCreate ?? Date(timeIntervalSince1970: 0)
        } set {
            _dateOfCreate = newValue
        }
    }
    
    var dateOfUpdate: Date { get {
        return _dateOfUpdate ?? Date(timeIntervalSince1970: 0)
        } set {
            _dateOfUpdate = newValue
        }
    }



}
