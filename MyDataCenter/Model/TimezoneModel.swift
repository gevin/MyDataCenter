//
//  TimezoneModel+CoreDataClass.swift
//  MyDataCenter
//
//  Created by GevinChen on 2019/7/25.
//  Copyright © 2019 GevinChen. All rights reserved.
//
//

import Foundation
import CoreData

@objc(TimezoneModel)
public class TimezoneModel: NSManagedObject, Codable {
    
    @NSManaged public var offset: String?
    @NSManaged public var locDescription: String?
    
    enum CodingKeys: String, CodingKey {
        case offset
        case locDescription = "description"
    }
    
    // MARK: - Decodable
    // json -> Model
    required convenience public init(from decoder: Decoder) throws {
        
        let context = DataCenter.shared.managedObjectContext
        guard let entity = NSEntityDescription.entity(forEntityName: TimezoneModel.entityName, in: context) else { fatalError() }
        self.init(entity: entity, insertInto: nil)
        
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.offset         = try container.decodeIfPresent( String.self, forKey: .offset         )
        self.locDescription = try container.decodeIfPresent( String.self, forKey: .locDescription )
    }
    
    // MARK: - Encodable
    // model -> json
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode( offset         , forKey: .offset         )
        try container.encode( locDescription , forKey: .locDescription )
    }
}
