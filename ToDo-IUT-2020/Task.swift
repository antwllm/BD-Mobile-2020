//
//  Task.swift
//  ToDo-IUT-2020
//
//  Created by William Antwi on 14/04/2020.
//  Copyright © 2020 Appsolute SARL. All rights reserved.
//

import Foundation

class Task {
    
    var name: String
    var checked: Bool
    var firebaseId: String?
    var updatedAt: Date
    var createdAt: Date
    
    private enum Field : String{
        case name
        case checked
        case firebaseId
        case updatedAt
        case createdAt
    }
    
    init(_ name: String, checked: Bool = false, createdAt: Date = Date(), updatedAt: Date = Date()) {
        
        self.name = name
        self.checked = checked
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
    
    init(_ dictionary: [String : Any]) {
        
        self.name = dictionary[Field.name.rawValue] as? String ?? ""
        self.checked = dictionary[Field.checked.rawValue] as? Bool ?? false
        self.createdAt = Date(timeIntervalSince1970: dictionary[Field.createdAt.rawValue] as? Double ?? 0)
        self.updatedAt = Date(timeIntervalSince1970: dictionary[Field.createdAt.rawValue] as? Double ?? 0)
    }
    
    func update(withDicytionary dictionary: [String : Any]) {
        
        self.name = dictionary[Field.name.rawValue] as? String ?? ""
        self.checked = dictionary[Field.checked.rawValue] as? Bool ?? false
        self.createdAt = Date(timeIntervalSince1970: dictionary[Field.createdAt.rawValue] as? Double ?? 0)
        self.updatedAt = Date(timeIntervalSince1970: dictionary[Field.updatedAt.rawValue] as? Double ?? 0)
    }
    
    func postDict() -> [String : Any] {
        
        return
            [ Field.name.rawValue: name,
              Field.checked.rawValue : checked,
              Field.createdAt.rawValue : createdAt.timeIntervalSince1970,
              Field.updatedAt.rawValue : updatedAt.timeIntervalSince1970]
        
    }
}
