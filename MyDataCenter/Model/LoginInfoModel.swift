//
//  LoginInfoModel+CoreDataClass.swift
//  MyDataCenter
//
//  Created by GevinChen on 2019/7/25.
//  Copyright © 2019 GevinChen. All rights reserved.
//
//

import Foundation
import CoreData

@objc(LoginInfoModel)
public class LoginInfoModel: NSManagedObject, Codable {
    @NSManaged public var uuid: String?
    @NSManaged public var username: String?
    @NSManaged public var password: String?
    @NSManaged public var salt: String?
    @NSManaged public var md5: String?
    @NSManaged public var sha1: String?
    @NSManaged public var sha256: String?
    
    enum CodingKeys: String, CodingKey {
        case uuid
        case username
        case password
        case salt
        case md5
        case sha1
        case sha256 
    }
    
    // MARK: - Decodable
    // json -> Model
    required convenience public init(from decoder: Decoder) throws {
        
        let context = DataCenter.shared.managedObjectContext
        guard let entity = NSEntityDescription.entity(forEntityName: LoginInfoModel.entityName, in: context) else { fatalError() }
        self.init(entity: entity, insertInto: nil)
        
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.uuid     = try container.decodeIfPresent( String.self, forKey: .uuid     )
        self.username = try container.decodeIfPresent( String.self, forKey: .username )
        self.password = try container.decodeIfPresent( String.self, forKey: .password )
        self.salt     = try container.decodeIfPresent( String.self, forKey: .salt     )
        self.md5      = try container.decodeIfPresent( String.self, forKey: .md5      )
        self.sha1     = try container.decodeIfPresent( String.self, forKey: .sha1     )
        self.sha256   = try container.decodeIfPresent( String.self, forKey: .sha256   )
    }
    
    // MARK: - Encodable
    // model -> json
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode( uuid     , forKey: .uuid     )
        try container.encode( username , forKey: .username )
        try container.encode( password , forKey: .password )
        try container.encode( salt     , forKey: .salt     )
        try container.encode( md5      , forKey: .md5      )
        try container.encode( sha1     , forKey: .sha1     )
        try container.encode( sha256   , forKey: .sha256   )
    }
}
