//
//  UserCellModel.swift
//  MyDataCenter
//
//  Created by GevinChen on 2019/7/25.
//  Copyright © 2019 GevinChen. All rights reserved.
//

import UIKit

struct UserCellModel {
    var userId: String
    var userPic: UIImage?
    var userName: String
    var location: String
    var email: String
    var phone: String
    var birthday: String
    var age: Int
    
    private var target: AnyObject?
    private var action: Selector?
    
    init(userId: String, userPic: UIImage?, userName: String, location: String, email: String, phone: String, birthday: String, age: Int) {
        self.userId = userId 
        self.userPic = userPic
        self.userName = userName
        self.location = location
        self.email = email
        self.phone = phone
        self.birthday = birthday
        self.age = age
    }
    
    mutating func setUserPic( image: UIImage? ) {
        self.userPic = image
    }
    
    mutating func setAction( target: AnyObject, method: Selector) {
        self.target = target
        self.action = method
    }
    
    func performAction() {
        self.target?.perform(self.action, with: self.userId)
    }
    
}
