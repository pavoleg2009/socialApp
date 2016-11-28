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
           if _email == nil {
            _email = ""
            }
            return _email 
        } set {
            _email = newValue
        }
        
    }
    
    var provider: String {
        get {
            if _provider == nil {
                _provider = ""
            }
            return _provider
        } set {
            _provider = newValue
        }
    }
    
    var avatarUrl: String {
        get {
            if _avatarUrl == nil {
                _avatarUrl = ""
            }
            return _avatarUrl
        } set {
            _avatarUrl = newValue
        }
    }
    
    init() {
        self.userKey = ""
        self._userName = ""
        self._email = ""
        self._provider = ""
        
    }
    
    init(userKey: String, userName: String, email: String, provider: String) {
        self.userKey = userKey
        self._userName = userName
        self._email = email
        self._provider = provider
        
    }
}
