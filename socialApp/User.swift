//
//  User.swift
//  socialApp
//
//  Created by Oleg Pavlichenkov on 09/11/2016.
//  Copyright © 2016 Oleg Pavlichenkov. All rights reserved.
//

import Foundation

class User {
    
    private var _userName: String!
    
    
    var userName: String {
        if _userName == nil {
            _userName = ""
        }
        return _userName
    }
    
    init(userName: String) {
        self._userName = userName
    }
}
