//
//  NameModel+CoreDataClass.swift
//  MyDataCenter
//
//  Created by GevinChen on 2019/7/25.
//  Copyright © 2019 GevinChen. All rights reserved.
//
//

import Foundation
import CoreData

@objc(NameModel)
public class NameModel: NSManagedObject, Codable {
    @NSManaged public var title: String?
    @NSManaged public var first: String?
    @NSManaged public var last: String?
    
    enum CodingKeys: String, CodingKey {
        case title
        case first
        case last
    }
    
    // MARK: - Decodable
    // json -> Model
    required convenience public init(from decoder: Decoder) throws {
        
        let context = DataCenter.shared.managedObjectContext
        guard let entity = NSEntityDescription.entity(forEntityName: NameModel.entityName, in: context) else { fatalError() }
        self.init(entity: entity, insertInto: nil)
        
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.title = try container.decodeIfPresent( String.self, forKey: .title )
        self.first = try container.decodeIfPresent( String.self, forKey: .first )
        self.last  = try container.decodeIfPresent( String.self, forKey: .last  )
    }
    
    // MARK: - Encodable
    // model -> json
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode( title , forKey: .title )
        try container.encode( first , forKey: .first )
        try container.encode( last  , forKey: .last  )
    }
}
