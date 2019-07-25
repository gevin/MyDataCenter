//
//  UserModel+CoreDataClass.swift
//  MyDataCenter
//
//  Created by GevinChen on 2019/7/25.
//  Copyright © 2019 GevinChen. All rights reserved.
//
//

import Foundation
import CoreData

/*
 https://randomuser.me/
 
 https://randomuser.me/api/
 {
 "results": [
 {
 "gender": "male",
 "name": {
 "title": "mr",
 "first": "rolf",
 "last": "hegdal"
 },
 "location": {
 "street": "ljan terrasse 346",
 "city": "vear",
 "state": "rogaland",
 "postcode": "3095",
 "coordinates": {
 "latitude": "54.8646",
 "longitude": "-97.3136"
 },
 "timezone": {
 "offset": "-10:00",
 "description": "Hawaii" // description 是保留字，所以轉成 model 換名
 }
 },
 "email": "rolf.hegdal@example.com",
 "login": {
 "uuid": "c4168eac-84b8-46ea-b735-c9da9bfb97fd",
 "username": "bluefrog786",
 "password": "ingrid",
 "salt": "GtRFz4NE",
 "md5": "5c581c5748fc8c35bd7f16eac9efbb55",
 "sha1": "c3feb8887abed9ec1561b9aa2c9f58de21d1d3d9",
 "sha256": "684c478a98b43f1ef1703b35b8bbf61b27dbc93d52acd515e141e97e04447712"
 },
 "dob": {
 "date": "1975-11-12T06:34:44Z",
 "age": 42
 },
 "registered": {
 "date": "2015-11-04T22:09:36Z",
 "age": 2
 },
 "phone": "66976498",
 "cell": "40652479",
 "id": {
 "name": "FN",
 "value": "12117533881"
 },
 "picture": {
 "large": "https://randomuser.me/api/portraits/men/65.jpg",
 "medium": "https://randomuser.me/api/portraits/med/men/65.jpg",
 "thumbnail": "https://randomuser.me/api/portraits/thumb/men/65.jpg"
 },
 "nat": "NO"
 }
 ],
 "info": {
 "seed": "2da87e9305069f1d",
 "results": 1,
 "page": 1,
 "version": "1.2"
 }
 }
 */

@objc(UserModel)
public class UserModel: NSManagedObject, Codable {

    @NSManaged public var userId: String?
    @NSManaged public var gender: String?
    @NSManaged public var email: String?
    @NSManaged public var phone: String?
    @NSManaged public var cell: String?
    @NSManaged public var nat: String?
    @NSManaged public var name: NameModel?
    @NSManaged public var location: LocationModel?
    @NSManaged public var login: LoginInfoModel?
    @NSManaged public var dob: DateInfoModel?
    @NSManaged public var registered: DateInfoModel?
    @NSManaged public var id: IdentityModel?
    @NSManaged public var picture: PictureModel?
    
    enum CodingKeys: String, CodingKey {
        case gender
        case email
        case phone
        case cell
        case nat
        case name
        case location
        case login
        case dob
        case registered
        case id
        case picture
    }
    
    // MARK: - Decodable
    // json -> Model
    required convenience public init(from decoder: Decoder) throws {
        
        let context = DataCenter.shared.managedObjectContext
        guard let entity = NSEntityDescription.entity(forEntityName: UserModel.entityName, in: context) else { fatalError() }
        self.init(entity: entity, insertInto: nil)
        
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.gender     = try container.decodeIfPresent( String.self, forKey: .gender     )
        self.email      = try container.decodeIfPresent( String.self, forKey: .email      )
        self.phone      = try container.decodeIfPresent( String.self, forKey: .phone      )
        self.cell       = try container.decodeIfPresent( String.self, forKey: .cell       )
        self.nat        = try container.decodeIfPresent( String.self, forKey: .nat        )
        self.name       = try container.decodeIfPresent( NameModel.self, forKey: .name       )
        self.location   = try container.decodeIfPresent( LocationModel.self, forKey: .location   )
        self.login      = try container.decodeIfPresent( LoginInfoModel.self, forKey: .login      )
        self.dob        = try container.decodeIfPresent( DateInfoModel.self, forKey: .dob        )
        self.registered = try container.decodeIfPresent( DateInfoModel.self , forKey: .registered )
        self.id         = try container.decodeIfPresent( IdentityModel.self , forKey: .id         )
        self.picture    = try container.decodeIfPresent( PictureModel.self, forKey: .picture    )
    }
    
    // MARK: - Encodable
    // model -> json
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode( gender     , forKey: .gender     )
        try container.encode( email      , forKey: .email      )
        try container.encode( phone      , forKey: .phone      )
        try container.encode( cell       , forKey: .cell       )
        try container.encode( nat        , forKey: .nat        )
        try container.encode( name       , forKey: .name       )
        try container.encode( location   , forKey: .location   )
        try container.encode( login      , forKey: .login      )
        try container.encode( dob        , forKey: .dob        )
        try container.encode( registered , forKey: .registered )
        try container.encode( id         , forKey: .id         )
        try container.encode( picture    , forKey: .picture    )
    }
}
