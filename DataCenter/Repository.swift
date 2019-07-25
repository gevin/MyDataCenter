//
//  Repository.swift
//  GevinMVVMDemo
//
//  Created by GevinChen on 2018/9/12.
//  Copyright © 2018年 GevinChen. All rights reserved.
//

import Foundation
import CoreData

class Repository<ModelType: NSManagedObject> {
    
    static func addListener( listener: DataCenterListener ) {
        DataCenter.shared.addListener(listener: listener, modelType: ModelType.self)
    }
    
    static func removeListener( listener: DataCenterListener ) {
        DataCenter.shared.removeListener(listener: listener, modelType: ModelType.self)
    }
    
    static func removeListenerAllModel( listener: DataCenterListener ) {
        DataCenter.shared.removeListener(listener: listener)
    }
    
    /**
     生成一個 model，但是沒有直接插入db
     注意：未插入 db 的 model，沒有 managed context，如果你拿已插入db 的 model 跟它做關聯(Relationship)的話
     會發生 context 不一致的例外
     */
    static func createNew() -> ModelType {
        return DataCenter.shared.createNewEntity(entityClass: ModelType.self) as! ModelType
    }
    
    static func fetchOne() -> [ModelType] {
        return DataCenter.shared.fetchOne(from: ModelType.entityName) as! [ModelType]
    }
    
    /// limit 0 代表不限
    static func fetch(condition: String, arguments: [Any]? = nil, limit: Int) -> [ModelType] {
        return DataCenter.shared.fetch(from: ModelType.entityName, condition: condition, arguments: arguments, limit: limit) as! [ModelType]
    }
    
    /// limit 0 代表不限
    static func fetch(condition: String, arguments: [Any]? = nil, sortKey: String, ascending: Bool, limit: Int) -> [ModelType] {
        return DataCenter.shared.fetch(from: ModelType.entityName, condition: condition, arguments: arguments, sortKey: sortKey, ascending: ascending, limit: limit) as! [ModelType]
    }
    
    static func fetchAll() -> [ModelType] {
        return DataCenter.shared.fetchAll(from: ModelType.entityName) as! [ModelType]
    }
    
    static func fetchAll(sortKey: String, ascending: Bool) -> [ModelType] {
        return DataCenter.shared.fetchAll(from: ModelType.entityName, sortKey: sortKey, ascending: ascending) as! [ModelType]
    }
    
    /**
     生成一個 model 並且插入 db
     */
    @discardableResult
    static func createNewAndInsert( data: [String:Any] = [:]) -> ModelType {
        let object = DataCenter.shared.createNewEntity(entityName: ModelType.entityName)
        if data.count > 0 {
            object?.injectJSONObject(dict: data)
        }
        DataCenter.shared.insert(object!)
        return object as! ModelType
    }
    
    static func insert(object: ModelType) {
        DataCenter.shared.insert(object)
    }
    
    static func insertBatch(objects: [ModelType] ) {
        DataCenter.shared.insertBatch(objects)
    }
    
    static func delete(object: ModelType ) {
        DataCenter.shared.delete(object)
    }
    
    static func deleteBatch(objects: [ModelType] ) {
        DataCenter.shared.deleteBatch(objects)
    }
    
    static func delete(condition: String?, arguments: [Any]?) {
        DataCenter.shared.delete(from: ModelType.entityName, condition: condition, arguments: arguments)
    }
    
    static func deleteAll() {
        DataCenter.shared.deleteAll(from: ModelType.entityName)
    }
    
    static func injectData(from source: ModelType, to destination: ModelType ) {
        DataCenter.shared.injectData(from: source, to: destination)
    }
    
    static func injectJSON( object: ModelType, newData: [String:Any] ) {
        object.injectJSONObject(dict: newData)
        DataCenter.shared.saveContext()
    }
    
    static func copy(object: ModelType) throws -> ModelType {
        let newObj = try DataCenter.shared.copy(from: object) as! ModelType
        return newObj
    }
    
    @discardableResult
    static func insertOrUpdate( object: ModelType, primaryKeys: [String] ) -> ModelType {
        return DataCenter.shared.insertOrUpdate( object: object, uniqueKeys: primaryKeys) as! ModelType
    }
    
    @discardableResult
    static func insertOrUpdateBatch( objects: [ModelType], primaryKeys: [String] ) -> [ModelType] {
        return DataCenter.shared.insertOrUpdateBatch(objects: objects, uniqueKeys: primaryKeys) as! [ModelType]
    }
    
    static func save() {
        DataCenter.shared.saveContext()
    }
}
