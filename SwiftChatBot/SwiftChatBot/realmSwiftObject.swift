//
//  realmSwiftObject.swift
//  SwiftChatBot
//
//  Created by mac on 2017/4/17.
//  Copyright © 2017年 Meow.minithon.teama. All rights reserved.
//

import Foundation
import RealmSwift

class Message: Object {
    dynamic var senderID = ""
    dynamic var senderName = ""
    dynamic var senderMessage = ""
}
