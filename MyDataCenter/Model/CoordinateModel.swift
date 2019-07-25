//
//  CoordinateModel+CoreDataClass.swift
//  MyDataCenter
//
//  Created by GevinChen on 2019/7/25.
//  Copyright © 2019 GevinChen. All rights reserved.
//
//

import Foundation
import CoreData

@objc(CoordinateModel)
public class CoordinateModel: NSManagedObject, Codable {
    @NSManaged public var latitude: String?
    @NSManaged public var longitude: String?
    
    enum CodingKeys: String, CodingKey {
        case latitude
        case longitude
    }
    
    // MARK: - Decodable
    // json -> Model
    required convenience public init(from decoder: Decoder) throws {
        
        let context = DataCenter.shared.managedObjectContext
        guard let entity = NSEntityDescription.entity(forEntityName: CoordinateModel.entityName, in: context) else { fatalError() }
        self.init(entity: entity, insertInto: nil)
        
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.latitude  = try container.decodeIfPresent( String.self, forKey: .latitude  )
        self.longitude = try container.decodeIfPresent( String.self, forKey: .longitude )
    }
    
    // MARK: - Encodable
    // model -> json
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode( latitude  , forKey: .latitude  )
        try container.encode( longitude , forKey: .longitude )
    }
}
