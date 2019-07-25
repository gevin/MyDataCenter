//
//  DateInfoModel+CoreDataClass.swift
//  MyDataCenter
//
//  Created by GevinChen on 2019/7/25.
//  Copyright © 2019 GevinChen. All rights reserved.
//
//

import Foundation
import CoreData

@objc(DateInfoModel)
public class DateInfoModel: NSManagedObject, Codable {
    
    @NSManaged public var date: String?
    @NSManaged public var age: Int32

    enum CodingKeys: String, CodingKey {
        case date
        case age
    }
    
    // MARK: - Decodable
    // json -> Model
    required convenience public init(from decoder: Decoder) throws {
        
        let context = DataCenter.shared.managedObjectContext
        guard let entity = NSEntityDescription.entity(forEntityName: DateInfoModel.entityName, in: context) else { fatalError() }
        self.init(entity: entity, insertInto: nil)
        
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.date     = try container.decodeIfPresent( String.self, forKey: .date    )
        self.age      = try container.decodeIfPresent( Int32.self,  forKey: .age     ) ?? 0
    }
    
    // MARK: - Encodable
    // model -> json
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode( date    , forKey: .date    )
        try container.encode( age     , forKey: .age     )
    }
}
