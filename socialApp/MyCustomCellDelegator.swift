//
//  File.swift
//  socialApp
//
//  Created by Oleg Pavlichenkov on 17/11/2016.
//  Copyright © 2016 Oleg Pavlichenkov. All rights reserved.
//

import Foundation


protocol MyCustomCellDelegator {
    func callEditSegueFromCell(myData dataobject: AnyObject)
    func callCommentSegueFromCell(myData dataobject: AnyObject)
}
