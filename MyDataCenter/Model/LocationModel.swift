//
//  LocationModel+CoreDataClass.swift
//  MyDataCenter
//
//  Created by GevinChen on 2019/7/25.
//  Copyright © 2019 GevinChen. All rights reserved.
//
//

import Foundation
import CoreData

@objc(LocationModel)
public class LocationModel: NSManagedObject, Codable {
    @NSManaged public var street: String?
    @NSManaged public var city: String?
    @NSManaged public var state: String?
    @NSManaged public var postcode: String?
    @NSManaged public var coordinates: CoordinateModel?
    @NSManaged public var timezone: TimezoneModel?
    
    enum CodingKeys: String, CodingKey {
        case street
        case city
        case state
        case postcode
        case coordinates
        case timezone
    }
    
    // MARK: - Decodable
    // json -> Model
    required convenience public init(from decoder: Decoder) throws {
        
        let context = DataCenter.shared.managedObjectContext
        guard let entity = NSEntityDescription.entity(forEntityName: LocationModel.entityName, in: context) else { fatalError() }
        self.init(entity: entity, insertInto: nil)
        
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.street      = try container.decodeIfPresent( String.self, forKey: .street      )
        self.city        = try container.decodeIfPresent( String.self, forKey: .city        )
        self.state       = try container.decodeIfPresent( String.self, forKey: .state       )
        if let value = try? container.decodeIfPresent( Int32.self,  forKey: .postcode ) {
            self.postcode = String(value)
        } else {
            self.postcode = try? container.decodeIfPresent( String.self,  forKey: .postcode )
        }
        self.coordinates = try container.decodeIfPresent( CoordinateModel.self, forKey: .coordinates )
        self.timezone    = try container.decodeIfPresent( TimezoneModel.self, forKey: .timezone    )
    }
    
    // MARK: - Encodable
    // model -> json
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode( street      , forKey: .street      )
        try container.encode( city        , forKey: .city        )
        try container.encode( state       , forKey: .state       )
        try container.encode( postcode    , forKey: .postcode    )
        try container.encode( coordinates , forKey: .coordinates )
        try container.encode( timezone    , forKey: .timezone    )
    }
}
