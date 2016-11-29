//
//  User.swift
//  socialApp
//
//  Created by Oleg Pavlichenkov on 09/11/2016.
//  Copyright © 2016 Oleg Pavlichenkov. All rights reserved.
//

import Foundation

class User {
    
    private var _userKey: String!
    private var _userName: String!
    private var _email: String!
    private var _provider: String! // auth provider
    private var _avatarUrl: String!
    
    
    var userKey: String? {
        get {
            return _userKey
        } set {
            _userKey = newValue
        }
    }
    var userName: String {
        get {
            if _userName == nil {
                _userName = ""
            }
            return _userName
        } set {
            _userName = newValue
        }
    }
    
    var email: String {
        get {
            return _email ?? ""
        } set {
            _email = newValue
        }
    }
    
    var provider: String {
        get {
            return _provider ?? ""
        } set {
            _provider = newValue
        }
    }
    
    var avatarUrl: String {
        get {
            return _avatarUrl ?? ""
        } set {
            _avatarUrl = newValue
        }
    }
    
    init() {
        self._userKey = ""
        self._userName = ""
        self._email = ""
        self._provider = ""
        
    }
    
    init(userKey: String, userName: String, email: String, provider: String) {
        self._userKey = userKey
        self._userName = userName
        self._email = email
        self._provider = provider        
    }
    
    init(userKey: String, userData: [String : Any]) {
        
        self._userKey = userKey
        
        if let userName = userData["userName"] as? String {
            self._userName = userName
        }

        if let email = userData["email"]  as? String {
            self._email = email
        }
        
        if let provider = userData["provider"]  as? String {
            self._provider = provider
        }
        
        if let avatarUrl = userData["avatarUrl"] as? String {
            self._avatarUrl = avatarUrl
        }

        
//        if let dateOfCreate = userData["dateOfCreate"]  as? TimeInterval {
//            self._dateOfCreate = Date(timeIntervalSince1970: dateOfCreate/1000)
//        }
//        
//        if let dateOfUpdate = userData["dateOfUpdate"]  as? TimeInterval {
//            self._dateOfUpdate = Date(timeIntervalSince1970: dateOfUpdate/1000)
//        }
        
//        _userRef = DataService.ds.REF_POSTS.child(_userKey)
        
    }
}
