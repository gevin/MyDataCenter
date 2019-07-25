//
//  IdentityModel+CoreDataClass.swift
//  MyDataCenter
//
//  Created by GevinChen on 2019/7/25.
//  Copyright © 2019 GevinChen. All rights reserved.
//
//

import Foundation
import CoreData

@objc(IdentityModel)
public class IdentityModel: NSManagedObject, Codable {

    @NSManaged public var name: String?
    @NSManaged public var value: String?
    
    enum CodingKeys: String, CodingKey {
        case name
        case value
    }
    
    // MARK: - Decodable
    // json -> Model
    required convenience public init(from decoder: Decoder) throws {
        
        let context = DataCenter.shared.managedObjectContext
        guard let entity = NSEntityDescription.entity(forEntityName: IdentityModel.entityName, in: context) else { fatalError() }
        self.init(entity: entity, insertInto: nil)
        
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.name      = try container.decodeIfPresent( String.self, forKey: .name  )
        self.value     = try container.decodeIfPresent( String.self, forKey: .value )
    }
    
    // MARK: - Encodable
    // model -> json
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode( name  , forKey: .name   )
        try container.encode( value , forKey: .value  )
    }
}
