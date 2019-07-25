//
//  PictureModel+CoreDataClass.swift
//  MyDataCenter
//
//  Created by GevinChen on 2019/7/25.
//  Copyright © 2019 GevinChen. All rights reserved.
//
//

import Foundation
import CoreData

@objc(PictureModel)
public class PictureModel: NSManagedObject, Codable {
    
    @NSManaged public var large: String?
    @NSManaged public var medium: String?
    @NSManaged public var thumbnail: String?
    
    enum CodingKeys: String, CodingKey {
        case large
        case medium
        case thumbnail
    }
    
    // MARK: - Decodable
    // json -> Model
    required convenience public init(from decoder: Decoder) throws {
        
        let context = DataCenter.shared.managedObjectContext
        guard let entity = NSEntityDescription.entity(forEntityName: PictureModel.entityName, in: context) else { fatalError() }
        self.init(entity: entity, insertInto: nil)
        
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.large      = try container.decodeIfPresent( String.self, forKey: .large     )
        self.medium     = try container.decodeIfPresent( String.self, forKey: .medium    )
        self.thumbnail  = try container.decodeIfPresent( String.self, forKey: .thumbnail )
    }
    
    // MARK: - Encodable
    // model -> json
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode( large     , forKey: .large     )
        try container.encode( medium    , forKey: .medium    )
        try container.encode( thumbnail , forKey: .thumbnail )
    }
}
