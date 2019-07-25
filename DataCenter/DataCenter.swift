//
//  DataCenter.swift
//  GevinMVVMDemo
//
//  Created by GevinChen on 2018/4/23.
//  Copyright © 2018年 GevinChen. All rights reserved.
//

import Foundation
import CoreData

protocol DataCenterListener {
    func dataModelChanged( change: ModelChange )
    
}

enum ModelChangeType {
    case inserted
    case updated
    case removed
}

struct ModelChange {
    var entityName: String = ""
    var objects: [ModelChangeType: [NSManagedObject] ] = [:]
    
    init( entityName: String) {
        self.entityName = entityName
        self.objects = [:]
    }
}

class DataCenter: NSObject {
    
    // MARK: - delegate
    
    private var _listenerDict: [String:[DataCenterListener]] = [:]
    
    // MARK: - property
    
    private var _dbName: String = "Model.db"
    private var _xcModelName: String = "Model"
    
    // MARK: - singleton
    static let shared: DataCenter = {
        let instance = DataCenter()
        return instance
    }()
    
    // MARK: - init
    public override init() {
        
        super.init()
        if #available(iOS 10, *) {
            _ = self.persistentContainer
        } else {
            _ = self.managedObjectContext
        }
        self.observeCoreData()
    }

    // MARK: - Core Data stack

    @available(iOS 10.0, *)
    public lazy var persistentContainer: NSPersistentContainer = {
        /*
         The persistent container for the application. This implementation
         creates and returns a container, having loaded the store for the
         application to it. This property is optional since there are legitimate
         error conditions that could cause the creation of the store to fail.
         */
        let container = NSPersistentContainer(name: _xcModelName)
        let description = NSPersistentStoreDescription.init(url: URL.init(fileURLWithPath: self.dbPath()))
        description.shouldInferMappingModelAutomatically = true
        description.shouldMigrateStoreAutomatically = true
        container.persistentStoreDescriptions = [description]
        container.loadPersistentStores(completionHandler: { (_, error) in
            if let error = error as NSError? {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.

                /*
                 Typical reasons for an error here include:
                 * The parent directory does not exist, cannot be created, or disallows writing.
                 * The persistent store is not accessible, due to permissions or data protection when the device is locked.
                 * The device is out of space.
                 * The store could not be migrated to the current model version.
                 Check the error message to determine what the actual problem was.
                 */
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
        return container
    }()

        // Returns the managed object context for the application.
        // If the context doesn't already exist, it is created and bound to the persistent store coordinator for the application.
    public lazy var managedObjectContext: NSManagedObjectContext = {
        if #available(iOS 10.0, *) {
            return self.persistentContainer.viewContext
        } else {
            let context = NSManagedObjectContext.init(concurrencyType: NSManagedObjectContextConcurrencyType.mainQueueConcurrencyType)
            context.persistentStoreCoordinator = self.persistentStoreCoordinator
            return context
        }
    }()

    public lazy var persistentStoreCoordinator: NSPersistentStoreCoordinator = {
        if #available(iOS 10.0, *) {
            return self.persistentContainer.persistentStoreCoordinator
        } else {
            let coordinator = NSPersistentStoreCoordinator.init(managedObjectModel: self.manageObjectModel)
            do {
                try coordinator.addPersistentStore(ofType: NSSQLiteStoreType,
                                           configurationName: nil,
                                           at: URL.init(string: self.dbPath()),
                                           options: nil)
                return coordinator
            } catch {
                print("error \(error)")

                do {
                    try FileManager.default.removeItem(atPath: self.dbPath())
                } catch {
                    print(error)
                }

                do {
                    try coordinator.addPersistentStore(ofType: NSSQLiteStoreType,
                                                       configurationName: nil,
                                                       at: URL.init(string: self.dbPath()),
                                                       options: nil)
                } catch {
                    abort()
                }
                return coordinator
            }
        }
    }()

    public lazy var manageObjectModel: NSManagedObjectModel = {
        if #available( iOS 10.0, *) {
            return self.persistentContainer.managedObjectModel
        } else {
            let modelUrl = Bundle.main.url(forResource: _xcModelName, withExtension: "momd")
            let model: NSManagedObjectModel = NSManagedObjectModel.init(contentsOf: modelUrl!)!
            return model
        }
    }()

    public func dbPath() -> String {
        //  取得 group 的 folder
    //    NSURL *directory = [NSFileManager.defaultManager containerURLForSecurityApplicationGroupIdentifier:@"group.com.mrbone.mimitalks" ];

        //  取得自己 app 的 document folder
        var paths = NSSearchPathForDirectoriesInDomains(FileManager.SearchPathDirectory.documentDirectory, FileManager.SearchPathDomainMask.userDomainMask, true)
        let directory: String = paths[0]

        let dbPath: String = "\(directory)/\(self.dbName())"
        print("Data Store \(dbPath)")
        return dbPath
    }

    public func dbName() -> String {
        return _dbName
    }

    // MARK: - Core Data Notification

    func observeCoreData() {
        NotificationCenter.default.addObserver(self, selector: #selector(handleDataModelChanged(notification:)), name: NSNotification.Name.NSManagedObjectContextObjectsDidChange, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(handleDataModelSaved(notification:)), name: NSNotification.Name.NSManagedObjectContextDidSave, object: nil)
    }

    func deobserveCoreData() {
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.NSManagedObjectContextObjectsDidChange, object: nil)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.NSManagedObjectContextDidSave, object: nil)
    }

    /**
     監聽系統的 NSManagedObject 更新事件。
     
     假設上一個 run loop 發生了 A、B、C 三個 model 都有更新，觸發事件的這個 run loop
     就會收到3個 model 的更新訊息
     可透過 notification.userInfo[NSUpdatedObjectsKey] 來取得更新的物件陣列
     
     */
    @objc func handleDataModelChanged(notification: Notification) {
        if let userInfo = notification.userInfo {
            let updateObjs: Set<NSManagedObject> = userInfo[NSUpdatedObjectsKey] as? Set<NSManagedObject> ?? Set<NSManagedObject>()

            if updateObjs.count>0 {
                
                var changeDict: [String: ModelChange ] = [:]
                for object in updateObjs {
                    let entityName = object.entity.name ?? ""
                    if var change = changeDict[entityName] {
                        change.objects[ModelChangeType.updated]?.append(object)
                        changeDict[entityName] = change
                    } else {
                        var change = ModelChange(entityName: entityName)
                        change.objects[ModelChangeType.updated] = []
                        change.objects[ModelChangeType.updated]?.append(object)
                        changeDict[entityName] = change
                    }
                }
                
                // 依 entityName 拿出 listener array，對每個 listener 發出通知
                for (entityName, change) in changeDict {
                    print("# DataCenter update # \(entityName) count:\(change.objects[ModelChangeType.updated]?.count ?? 0)")
                    if let listenerArray = self._listenerDict[entityName] {
                        for listener in listenerArray {
                            listener.dataModelChanged(change: change)
                        }
                    }
                }
                
            }
        }
    }

    /**
     監聽系統的 NSManagedObject 儲存事件。
     
     假設上一個 run loop 發生了 A、B model 存入 DB， C model 刪除，觸發事件的這個 run loop
     就會收到 
     notification.userInfo[NSInsertedObjectsKey] 有兩個物件
     notification.userInfo[NSDeletedObjectsKey]  有一個物件
     */
    @objc func handleDataModelSaved(notification: Notification) {

        if let userInfo = notification.userInfo {
            let deleteObjs: Set<NSManagedObject> = userInfo[NSDeletedObjectsKey] as? Set<NSManagedObject> ?? Set<NSManagedObject>()
            let insertObjs: Set<NSManagedObject> = userInfo[NSInsertedObjectsKey] as? Set<NSManagedObject> ?? Set<NSManagedObject>()

            // key (modelName)
            var changeDict: [String: ModelChange ] = [:]
            if deleteObjs.count>0 {
                for object in deleteObjs {
                    let entityName = object.entity.name ?? ""
                    if var change = changeDict[entityName] {
                        change.objects[ModelChangeType.removed]?.append(object)
                        changeDict[entityName] = change
                    } else {
                        var change = ModelChange(entityName: entityName)
                        change.objects[ModelChangeType.removed] = []
                        change.objects[ModelChangeType.removed]?.append(object)
                        changeDict[entityName] = change
                    }
                }
            }

            if insertObjs.count>0 {
                for object in insertObjs {
                    let entityName = object.entity.name ?? ""
                    if var change = changeDict[entityName] {
                        change.objects[ModelChangeType.inserted]?.append(object)
                        changeDict[entityName] = change
                    } else {
                        var change = ModelChange(entityName: entityName)
                        change.objects[ModelChangeType.inserted] = []
                        change.objects[ModelChangeType.inserted]?.append(object)
                        changeDict[entityName] = change
                    }
                }
            }
            
            // 依 entityName 拿出 listener array，對每個 listener 發出通知
            for (entityName, change) in changeDict {
                if change.objects[ModelChangeType.removed] != nil { 
                    print("# DataCenter delete # \(entityName) count:\(change.objects[ModelChangeType.removed]?.count ?? 0)") 
                }
                if change.objects[ModelChangeType.inserted] != nil {
                    print("# DataCenter insert # \(entityName) count:\(change.objects[ModelChangeType.inserted]?.count ?? 0)") 
                }
                
                if let listenerArray = self._listenerDict[entityName] {
                    for listener in listenerArray {
                        listener.dataModelChanged(change: change)
                    }
                }
            }
        }
    }
    
    // MARK: - Listener

    public func addListener<ModelType: NSManagedObject>( listener: DataCenterListener, modelType: ModelType.Type ) {
        
        if var listenerArray = _listenerDict[ModelType.entityName] {
            let object1: AnyObject = listener as AnyObject
            for listener1 in listenerArray {
                let object2: AnyObject = listener1 as AnyObject
                if object2 === object1 {
                    return
                }
            } 
            listenerArray.append(listener)
            _listenerDict[ModelType.entityName] = listenerArray
        }
        else {
            var listenerArray: [DataCenterListener] = []
            listenerArray.append(listener)
            _listenerDict[ModelType.entityName] = listenerArray
        }
    }
    
    public func removeListener<ModelType: NSManagedObject>( listener: DataCenterListener, modelType: ModelType.Type ) {
        if var listenerArray = _listenerDict[ModelType.entityName] {
            let object1: AnyObject = listener as AnyObject
            for i in 0..<listenerArray.count {
                let listener1 = listenerArray[i]
                let object2: AnyObject = listener1 as AnyObject
                if object2 === object1 {
                    listenerArray.remove(at: i)
                    break
                }
            } 
            _listenerDict[ModelType.entityName] = listenerArray
        }
    }
    
    public func removeListener( listener: DataCenterListener ) {
        let entityNames = _listenerDict.map({$0.key})
        let object1: AnyObject = listener as AnyObject
        for entityName in entityNames {
            guard var listenerArray = _listenerDict[entityName] else {continue} 
            for i in 0..<listenerArray.count {
                let listener1 = listenerArray[i]
                let object2: AnyObject = listener1 as AnyObject
                if object2 === object1 {
                    listenerArray.remove(at: i)
                    break
                }
            } 
            _listenerDict[entityName] = listenerArray
        }
    }

    // MARK: - Core Data Saving support

    public func saveContext () {
        let context = self.managedObjectContext
        
        /*
        針對多線程的 context 資料的合併
        定了保存时合并数据发生冲突时如何应对，该属性有以下几种值：
         1.NSErrorMergePolicy : 默认策略，有冲突时保存失败，persistent store 和 context 都维持原样，并返回错误信息，是唯一反馈错误信息的合并策略。
         2.NSMergeByPropertyStoreTrumpMergePolicy : 当 persistent store 和 context 里的版本有冲突，persistent store 里的版本有优先权， context 里使用 persistent store 里的版本替换。
         3.NSMergeByPropertyObjectTrumpMergePolicy : 与上面相反，context 里的版本有优先权，persistent store 里使用 context 里的版本替换。
         4.NSOverwriteMergePolicy : 用 context 里的版本强制覆盖 persistent store 里的版本。
         5.NSRollbackMergePolicy : 放弃 context 中的所有变化并使用 persistent store 中的版本进行替换。
        
         */
        context.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                let nserror = error as NSError
                print("Unresolved error \(nserror)")
            }
        }
    }
    
    // MARK: - Fetch
    
    public func fetchOne(from tableName: String) -> [NSManagedObject] {
        let context = self.managedObjectContext
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: tableName)
        fetchRequest.fetchLimit = 1
        do {
            let result = try context.fetch(fetchRequest)
            return result as! [NSManagedObject]
        } catch {
            print(error)
        }
        return []
    }

    public func fetchAll(from tableName: String ) -> [NSManagedObject] {
        return self.fetchAll(from: tableName, sortKey: "", ascending: false)
    }
    
    public func fetchAll(from tableName: String, sortKey: String, ascending: Bool ) -> [NSManagedObject] {
        let context = self.managedObjectContext
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>.init(entityName: tableName)
        if sortKey.count > 0 {
            // Configure the request's entity, and optionally its predicate
            fetchRequest.sortDescriptors = [NSSortDescriptor(key: sortKey, ascending: ascending)]
        }
        do {
            let result = try context.fetch(fetchRequest)
            return result as! [NSManagedObject]
        } catch {
            print(error)
        }
        return []
    }

    public func fetch(from tableName: String, condition: String, arguments: [Any]? = nil, limit: Int = 0) -> [NSManagedObject] {
        return self.fetch(from: tableName, condition: condition, arguments: arguments, sortKey: "", ascending: true, limit: limit)
    }
    
    public func fetch(from tableName: String, condition: String, arguments: [Any]? = nil, sortKey: String, ascending: Bool, limit: Int = 0 ) -> [NSManagedObject] {
        let context = self.managedObjectContext
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>.init(entityName: tableName)
        let predicate = NSPredicate.init(format: condition, argumentArray: arguments)
        fetchRequest.predicate = predicate
        if limit > 0 {
            fetchRequest.fetchLimit = limit
        }
        if sortKey.count > 0 {
            // Configure the request's entity, and optionally its predicate
            fetchRequest.sortDescriptors = [NSSortDescriptor(key: sortKey, ascending: ascending)]
        }
        do {
            let result = try context.fetch(fetchRequest)
            return result as! [NSManagedObject]
        } catch {
            print(error)
        }
        return []
    }
    
    // MARK: - Create

    public func createNewEntity(entityClass: AnyClass) -> NSManagedObject? {
        let entityName = String(describing: entityClass)
        return self.createNewEntity(entityName: entityName)
    }

    public func createNewEntity(entityName: String) -> NSManagedObject? {
        let context = self.managedObjectContext
        let entityDesc: NSEntityDescription? = NSEntityDescription.entity(forEntityName: entityName, in: context)
        if let entityDesc = entityDesc {
            let object = NSManagedObject(entity: entityDesc, insertInto: nil)
            
            // init property
            self.initProperty(object: object)
            
            // nest initial relation ship
            for (key,relationDesc) in object.entity.relationshipsByName {
//                print("property name:\(key)")
//                print("relationship class name: \(relationDesc.destinationEntity?.name ?? "" )")
                guard !relationDesc.isOptional else {
                    continue
                }
                guard let r_name = relationDesc.destinationEntity?.name else {
                    continue
                }
                    
                if relationDesc.isToMany {
                    // to many
                    let set = Set<NSManagedObject>()
                    object.setValue(set, forKey: key)
                } else {
                    let relation_obj = self.createNewEntity(entityName: r_name)
                    object.setValue(relation_obj, forKey: key)
                }
            }
            
            return object
        }
        return nil
    }
    
    func initProperty( object: NSManagedObject ) {
        for (key, attr) in object.entity.attributesByName {
            if !attr.isOptional {
                switch attr.attributeType {
                    
                case .undefinedAttributeType:
                    break
                case .integer16AttributeType:
                    object.setPrimitiveValue(0, forKey: key)
                case .integer32AttributeType:
                    object.setPrimitiveValue(0, forKey: key)
                case .integer64AttributeType:
                    object.setPrimitiveValue(0, forKey: key)
                case .decimalAttributeType:
                    object.setPrimitiveValue(0, forKey: key)
                case .doubleAttributeType:
                    object.setPrimitiveValue(0, forKey: key)
                case .floatAttributeType:
                    object.setPrimitiveValue(0, forKey: key)
                case .stringAttributeType:
                    object.setPrimitiveValue("", forKey: key)
                case .booleanAttributeType:
                    object.setPrimitiveValue(false, forKey: key)
                case .dateAttributeType:
                    break
                case .binaryDataAttributeType:
                    break
                case .UUIDAttributeType:
                    break
                case .URIAttributeType:
                    break
                case .transformableAttributeType:
//                    print("attribute class name: \(attr.attributeValueClassName)")

                    break
                case .objectIDAttributeType:
                    break
                }
            }
        }
    }
    
    // MARK: - Insert

    public func insertNewEntity(entityName: String) -> NSManagedObject? {
        let context = self.managedObjectContext
        let entityDesc: NSEntityDescription? = NSEntityDescription.entity(forEntityName: entityName, in: context)
        if let entityDesc = entityDesc {
            let object = NSManagedObject(entity: entityDesc, insertInto: context)

            return object
        }
        return nil
    }

    public func insert(_ object: NSManagedObject) {
        guard object.objectID.isTemporaryID == true else {
            return
        }
        let context = self.managedObjectContext

        for (name, _) in object.entity.relationshipsByName {
            let value = object.value(forKey: name)
            if let objects = value as? Set<NSManagedObject> {
                // one-to-many
                for obj in objects {
                    self.insertWithoutSave(obj)
                }
            } else if let obj = value as? NSManagedObject {
                // one-to-one
                self.insertWithoutSave(obj)
            }
        }
        
        context.insert(object)
        self.saveContext()
    }

    internal func insertWithoutSave(_ object: NSManagedObject) {
        // 有 isTemporaryID 表示已經存在 db，就不再 insert
        guard object.objectID.isTemporaryID == true else {
            return
        }
        let context = self.managedObjectContext

        for (name, _) in object.entity.relationshipsByName {
            let value = object.value(forKey: name)
            if let objects = value as? Set<NSManagedObject> {
                // one-to-many
                for obj in objects {
                    self.insertWithoutSave(obj)
                }
            } else if let obj = value as? NSManagedObject {
                // one-to-one
                self.insertWithoutSave(obj)
            }
        }

        context.insert(object)
    }

    public func insertBatch(_ objectArray: [NSManagedObject]) {
        guard objectArray.count > 0 else {
            return
        }
        let context = self.managedObjectContext
        for object in objectArray {
            guard object.objectID.isTemporaryID == true else {
                continue
            }
            for (name, _) in object.entity.relationshipsByName {
                let value = object.value(forKey: name)
                if let objects = value as? Set<NSManagedObject> {
                    // one-to-many
                    for obj in objects {
                        self.insertWithoutSave(obj)
                    }
                } else if let obj = value as? NSManagedObject {
                    // one-to-one
                    self.insertWithoutSave(obj)
                }
            }
            
            context.insert(object)
        }
        self.saveContext()
    }
    
    // MARK: - Insert Or Update

    // primaryKey 是指說，要以 data 中的哪個欄位來做為搜尋比對的依據
    public func insertOrUpdate( object: NSManagedObject, uniqueKeys: [String]) -> NSManagedObject? {
        guard let entityName = object.entity.name else { return nil }
        //
        let context = self.managedObjectContext
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>.init(entityName: entityName)
        
        var condition = ""
        var values:[Any] = []
        for pkey in uniqueKeys {
            guard let value = object.value(forKey: pkey) else { continue }
            values.append(value)
            if condition.count > 0 {
                condition = "\(condition) && \(pkey) == %@"
            } else {
                condition = "\(pkey) == %@"
            }
        }
        let predicate = NSPredicate(format: condition, argumentArray: values)
        fetchRequest.predicate = predicate
        fetchRequest.fetchLimit = 1
        var finalObject: NSManagedObject = object
        do {
            let result = try context.fetch(fetchRequest)
            if result.count>0 {
                // update
                if let oldObj = result[0] as? NSManagedObject {
                    self.injectData( from: object, to: oldObj )
                    finalObject = oldObj
                }
            } else {
                // insert
                self.insertWithoutSave(object)
            }
        } catch {
            print(error)
        }
        
        self.saveContext()
        return finalObject
    }
    
    public func insertOrUpdateBatch( objects: [NSManagedObject], uniqueKeys: [String]) -> [NSManagedObject] {
        guard objects.count > 0 else { return [] }
        guard let entityName = objects[0].entity.name else { return [] }
        
        let context = self.managedObjectContext
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>.init(entityName: entityName)
        var resultArr = [NSManagedObject]()
        for object in objects {
            var condition = ""
            var values:[Any] = []
            for pkey in uniqueKeys {
                guard let value = object.value(forKey: pkey) else { continue }
                values.append(value)
                if condition.count > 0 {
                    condition = "\(condition) && \(pkey) == %@"
                } else {
                    condition = "\(pkey) == %@"
                }
            }
            let predicate = NSPredicate.init(format: condition, argumentArray: values)
            fetchRequest.predicate = predicate
            fetchRequest.fetchLimit = 1
            do {
                let result = try context.fetch(fetchRequest)
                if result.count>0 {
                    
                    // update
                    if let oldObj = result[0] as? NSManagedObject {
                        self.injectData(from: object, to: oldObj )
                        resultArr.append(oldObj)
                    }
                } else {
                    self.insertWithoutSave(object)
                    resultArr.append(object)
                }
            } catch {
                print(error)
            }
        }
        
        self.saveContext()
        return resultArr
    }
    
    // primaryKey 是指說，要以 data 中的哪個欄位來做為搜尋比對的依據
    public func insertOrUpdateData(tableName: String, data: [String: Any], uniqueKeys: [String]) -> NSManagedObject? {
        
        guard data.count>0 else { return nil }
        // 
        let context = self.managedObjectContext
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>.init(entityName: tableName)
        // 搜尋條件
        var condition = ""
        var values:[Any] = []
        for pkey in uniqueKeys {
            guard  let value = data[pkey] else { continue }
            values.append(value)
            if condition.count > 0 {
                condition = "\(condition) && \(pkey) == %@"
            } else {
                condition = "\(pkey) == %@"
            }
        }
        let predicate = NSPredicate(format: condition, argumentArray: values)
        fetchRequest.predicate = predicate
        fetchRequest.fetchLimit = 1
        var object: NSManagedObject?
        do {
            let result = try context.fetch(fetchRequest)
            if result.count>0 {
                // update
                object = result[0] as? NSManagedObject
                object?.injectJSONObject(dict: data)
            } else {
                // insert
                object = NSEntityDescription.insertNewObject(forEntityName: tableName, into: context)
                object?.injectJSONObject(dict: data)
            }
        } catch {
            print(error)
        }

        self.saveContext()
        return object
    }

    public func insertOrUpdateDataBatch( tableName: String, datas: [[String: Any]], uniqueKeys: [String]) -> [NSManagedObject] {
        guard datas.count>0 else { return [] }
        // 
        let context = self.managedObjectContext
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>.init(entityName: tableName)
        var resultArr = [NSManagedObject]()
        for data in datas {
            var condition = ""
            var values:[Any] = []
            for pkey in uniqueKeys {
                guard  let value = data[pkey] else { continue }
                values.append(value)
                if condition.count > 0 {
                    condition = "\(condition) && \(pkey) == %@"
                } else {
                    condition = "\(pkey) == %@"
                }
            }
            let predicate = NSPredicate.init(format: condition, argumentArray: values)
            fetchRequest.predicate = predicate
            fetchRequest.fetchLimit = 1
            do {
                let result = try context.fetch(fetchRequest)
                if result.count>0 {
                    // update
                    let object: NSManagedObject = result[0] as! NSManagedObject
                    object.injectJSONObject(dict: data)
                    resultArr.append(object)
                } else {
                    // insert
                    let object: NSManagedObject = NSEntityDescription.insertNewObject(forEntityName: tableName, into: context)
                    object.injectJSONObject(dict: data)
                    resultArr.append(object)
                }
            } catch {
                print(error)
            }
        }

        self.saveContext()
        return resultArr
    }
    
    // MARK: - Update
    
    // 透過另一個 NSManagedObject 來更新自己
    public func injectData(from sourceObject: NSManagedObject, to destObject: NSManagedObject ) {
        // 把 object 的 attribute value 填到自己
        for (name, attr) in destObject.entity.attributesByName {
            let attrType = attr.attributeType
            if let value = sourceObject.value(forKey: name) {
                // 檢查 value type 是否與 attrType 一致
                guard destObject.checkTypeConsistent(value, attrType: attrType) else { continue }
                destObject.setValue(value, forKey: name)
            }
        }
        
        // 先檢查 relationship 裡的 object 是否有加到 db
        for (name, relationship) in sourceObject.entity.relationshipsByName {
            guard let relationType = relationship.destinationEntity?.name else { continue }
            if let value = sourceObject.value(forKey: name) {
                if let objects = value as? Set<NSManagedObject> {
                    // one-to-many
                    for obj in objects {
                        guard obj.objectID.isTemporaryID == true else {continue}
                        self.insertWithoutSave(obj)
                    }
                } else if let obj = value as? NSManagedObject {
                    if obj.objectID.isTemporaryID == true {
                        // one-to-one
                        self.insertWithoutSave(obj)
                    }
                }
            }
        }
        
        // 把 object 的 relationship object 填到自已
        for (name, relationship) in destObject.entity.relationshipsByName {
            guard let relationType = relationship.destinationEntity?.name else { continue }
            if let modelSet = sourceObject.value(forKey: name) {
                destObject.setValue(modelSet, forKey: name)
            }
        }
    }
    
    // MARK: - Copy 
    
    public func copy( from sourceObject: NSManagedObject ) throws -> NSManagedObject {
        guard let entityName = sourceObject.entity.name else {
            throw NSError(domain: "Copy NSManagedObject", code: -1, userInfo: [NSLocalizedDescriptionKey:"source object entity name is empty."])
        }
        guard let destObject = self.createNewEntity(entityName: entityName ) else {
            throw NSError(domain: "Copy NSManagedObject", code: -2, userInfo: [NSLocalizedDescriptionKey:"copy object can't create."])
        }
        
        // 把 object 的 attribute value 填到自己
        for (name, attr) in destObject.entity.attributesByName {
            let attrType = attr.attributeType
            if let value = sourceObject.value(forKey: name) {
                // 檢查 value type 是否與 attrType 一致
                guard destObject.checkTypeConsistent(value, attrType: attrType) else { continue }
                destObject.setValue(value, forKey: name)
            }
        }
        
        // 複製 source object 的 relationship 物件
        for (name, relationship) in sourceObject.entity.relationshipsByName {
            guard let relationType = relationship.destinationEntity?.name else { continue }
            if let value = sourceObject.value(forKey: name) {
                if let objects = value as? Set<NSManagedObject> {
                    // one-to-many
                    var newSet = Set<NSManagedObject>()
                    for obj in objects {
                        let newobj = try self.copy(from: obj)
                        newSet.insert(newobj)
                    }
                    destObject.setValue(newSet, forKey: name)
                } else if let obj = value as? NSManagedObject {        
                    // one-to-one
                    let newobj = try self.copy(from: obj)
                    destObject.setValue(newobj, forKey: name)
                }
            }
        }
        return destObject
    }
    
    // MARK: - Delete

    public func delete(_ object: NSManagedObject) {
        let context = self.managedObjectContext
        do {
            // 在 obj-c，若 object 不存在 context，就直接取回 nil，但在 swift 會丟出 exception，要用try catch 接
            _ = try context.existingObject(with: object.objectID)
        } catch {
            // print(error)
            return
        }

        context.delete(object)
        self.saveContext()
    }
    
    public func deleteBatch(_ objects: [NSManagedObject] ) {
        let context = self.managedObjectContext
        for object in objects {
            do {
                // 在 obj-c，若 object 不存在 context，就直接取回 nil，但在 swift 會丟出 exception，要用try catch 接
                _ = try context.existingObject(with: object.objectID)
            } catch {
                // print(error)
                continue
            }
            context.delete(object)
        }
        self.saveContext()
    }

    private func deleteWithoutSave(_ object: NSManagedObject) {
        let context = self.managedObjectContext
        do {
            // 在 obj-c，若 object 不存在 context，就直接取回 nil，但在 swift 會丟出 exception，要用try catch 接
            _ = try context.existingObject(with: object.objectID)
        } catch {
            // print(error)
            return
        }
        
        context.delete(object)
    }
    
    private func deleteBatchWithoutSave(_ objects: [NSManagedObject] ) {
        let context = self.managedObjectContext
        for object in objects {
            do {
                // 在 obj-c，若 object 不存在 context，就直接取回 nil，但在 swift 會丟出 exception，要用try catch 接
                _ = try context.existingObject(with: object.objectID)
            } catch {
                // print(error)
                continue
            }
            context.delete(object)
        }
    }
    
    public func delete(from tableName: String, condition: String?, arguments: [Any]?) {

        let context = self.managedObjectContext
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>.init(entityName: tableName)
        if let condition = condition {
            let predicate = NSPredicate.init(format: condition, argumentArray: arguments)
            fetchRequest.predicate = predicate
        }

        do {
            let result = try context.fetch(fetchRequest)
            for i in 0..<result.count {
                if let object = result[i] as? NSManagedObject {
                    context.delete(object)
                }
            }
            self.saveContext()
        } catch {
            print(error)
        }
    }

    public func deleteAll(from tableName: String) {
        self.delete(from: tableName, condition: nil, arguments: nil)
    }
}

protocol CoreDataEntityName {
    static var entityName: String { get }
}

extension CoreDataEntityName where Self: NSManagedObject {
    
//    static func asObservable() -> Observable<ModelChangeEvent> {
//        // 從 DataCenter 找看有沒有 table name 的 observable
//        return DataCenter.shared.getEntityObservable(entity: Self.self)
//    }
    
    static var entityName: String {
        return String(describing: Self.self)
    }
}

//protocol PropertyNames {
//    func propertyNames() -> [String]
//}
//
//extension PropertyNames
//{
//    func propertyNames() -> [String] {
//        return Mirror(reflecting: self).children.compactMap { $0.label }
//    }
//}

extension NSManagedObject {
    /// 值為 nil 的 attribute，給予初始值
    func attributesInitialize() {
        for (key, attr) in self.entity.attributesByName {
            // 若屬性非 optional 類型，但值又是 nil，就給予初始值
            // 注意：
            //  是否為 optional，並非在 NSManagedObject 的 class 宣告
            //  而是在 .xcdatamodeld 的 inspector 裡設定，選到 model，選 attribute
            //  右邊的細節設定，就會有一個 optional 的 checkbox，在那裡設定才有效
            if !attr.isOptional && self.value(forKey: key) == nil {
                switch attr.attributeType {
                    
                case .undefinedAttributeType:
                    break
                case .integer16AttributeType:
                    self.setPrimitiveValue(0, forKey: key)
                case .integer32AttributeType:
                    self.setPrimitiveValue(0, forKey: key)
                case .integer64AttributeType:
                    self.setPrimitiveValue(0, forKey: key)
                case .decimalAttributeType:
                    self.setPrimitiveValue(0, forKey: key)
                case .doubleAttributeType:
                    self.setPrimitiveValue(0, forKey: key)
                case .floatAttributeType:
                    self.setPrimitiveValue(0, forKey: key)
                case .stringAttributeType:
                    self.setPrimitiveValue("", forKey: key)
                case .booleanAttributeType:
                    self.setPrimitiveValue(false, forKey: key)
                case .dateAttributeType:
                    self.setPrimitiveValue(Date(), forKey: key)
                    break
                case .binaryDataAttributeType:
                    self.setPrimitiveValue(Data(), forKey: key)
                    break
                case .UUIDAttributeType:
                    self.setPrimitiveValue(UUID(), forKey: key)
                    break
                case .URIAttributeType:
                    break
                case .transformableAttributeType:
                    break
                case .objectIDAttributeType:
                    break
                }
            }
        }
    }
}

extension NSManagedObject: CoreDataEntityName {

    func injectData( from source: NSManagedObject ) {
        DataCenter.shared.injectData(from: source, to: self)
    }
    
    // 把 dictionary 的資料，填到 NSManagedObject
    // https://stackoverflow.com/questions/34411934/swift-reflecting-properties-of-subclass-of-nsmanagedobject
    func injectJSONObject(dict: [String: Any]) {
        for (name, attr) in  self.entity.attributesByName {
            let attrType = attr.attributeType // NSAttributeType enumeration for the property type
            if let value = dict[name] {
                // 若為 nil 就略過
                guard !(value is NSNull) else { continue }

                // 檢查 value type 是否與 attrType 一致
                guard self.checkTypeConsistent(value, attrType: attrType) else { continue }
                self.setValue(value, forKey: name)
            }
        }
        // print("------- relationship ------")
        for (name, relationship) in self.entity.relationshipsByName {
            guard let relationType = relationship.destinationEntity?.name else { continue }
            var relationObject = self.value(forKey: name) as? NSManagedObject
            // 若自己的 relationship 沒值，就初始一個新的
            if relationObject == nil {
                if self.managedObjectContext != nil {
                    //  若 parent object 已經是在 db 裡的資料，subObject 就直接 insert，因為 object relationship，context 必須相同  
                    relationObject = DataCenter.shared.insertNewEntity(entityName: relationType)
                } else {
                    relationObject = DataCenter.shared.createNewEntity(entityName: relationType)
                }
                self.setValue(relationObject, forKey: name)
            }
            // 把資料填入 relationsip 的 object
            if let value = dict[name] as? [String: Any] {
                relationObject?.injectJSONObject( dict: value )
            }
        }
    }

    // 檢查欲填入的資料，是否符合 attribute 的 data type
    func checkTypeConsistent(_ value: Any, attrType: NSAttributeType) -> Bool {
        if  attrType == .integer16AttributeType ||
            attrType == .integer32AttributeType ||
            attrType == .integer64AttributeType ||
            attrType == .decimalAttributeType {
            if  (value is Int) ||
                (value is Int16) ||
                (value is Int32) ||
                (value is Int64) ||
                (value is NSNumber) {
                return true
            }
        } else if  attrType == .doubleAttributeType ||
            attrType == .floatAttributeType {
            if  value is NSNumber ||
                value is Float || value is Double {
                return true
            }
        } else if attrType == .stringAttributeType {
            if  value is String ||
                value is NSString {
                return true
            }
        } else if attrType == .booleanAttributeType {
            if  value is Bool ||
                value is NSNumber {
                return true
            }
        } else if attrType == .dateAttributeType {
            if  value is Date ||
                value is NSDate {
                return true
            }
        } else if attrType == .binaryDataAttributeType {
            if  value is Data ||
                value is NSData {
                return true
            }
        }
        //  這4個type 我不做檢查因為不知道實際 type 是啥
        else if #available(iOS 11, *), ( attrType == .UUIDAttributeType || attrType == .URIAttributeType || attrType == .transformableAttributeType || attrType == .objectIDAttributeType ) {
            return true
        }

        return false
    }
    
}
