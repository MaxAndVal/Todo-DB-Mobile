//
//  DataManager.swift
//  DoItDBMobile
//
//  Created by MALOSSE Maxime on 18/03/2019.
//  Copyright © 2019 MALOSSE Maxime. All rights reserved.
//

import UIKit
import CoreData
import Firebase


class DataManager {
    
    var ref: DatabaseReference!
    static let SharedDataManager = DataManager()
    
    var context: NSManagedObjectContext {
        
        get {
            return persistentContainer.viewContext
        }
    }
    
    
    private init() {
        ref = Database.database().reference(fromURL: "https://todoapp-e390f.firebaseio.com/")
    }
    
    // MARK: - Core Data stack
    
    fileprivate lazy var persistentContainer: NSPersistentContainer = {
        
        let container = NSPersistentContainer(name: "DoItDBMobile")
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
        return container
    }()
    
    // MARK: - Core Data Saving support
    
    fileprivate func saveContext() {
        let context = persistentContainer.viewContext
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                
                let nserror = error as NSError
                fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
            }
        }
    }
    
    func saveData() {
        saveContext()
    }
    
    
    //MARK : - FireBase methods
    func saveFireBase() {
        let todoItemsRequest: NSFetchRequest<TodoItem> = NSFetchRequest<TodoItem>(entityName: "TodoItem")
        do {
            let fetchedResults = try self.context.fetch(todoItemsRequest)
            let results = fetchedResults as [NSManagedObject]
            guard let user = Auth.auth().currentUser else {
                return
            }
            for item in results {
                if let realItem = item as? TodoItem {
                    let updatedTodoItem = realItem.toSerialized()
                    self.ref.child("users").child(user.uid).child("userData").child("TodoItems").child((item as! TodoItem).id!).updateChildValues(updatedTodoItem as [AnyHashable : Any])
                }
                
            }
            print("TodoItems saved to Firebase")
        } catch let error as NSError {
            print("Could not fetch : \(error)")
        }
        
        let categoryRequest: NSFetchRequest<Category> = NSFetchRequest<Category>(entityName: "Category")
        do {
            let fetchedResults = try self.context.fetch(categoryRequest)
            let results = fetchedResults as [NSManagedObject]
            
            guard let user = Auth.auth().currentUser else {
                return
            }
            
            for item in results {
                let updatedCat = (item as! Category).toSerialized()
                self.ref.child("users").child(user.uid).child("userData").child("Categories").child((item as! Category).id!).updateChildValues(updatedCat as [AnyHashable : Any])
            }
            print("Categories saved to Firebase")
        } catch let error as NSError {
            print("Could not fetch : \(error)")
        }
        
    }
    
    func loadCatFromFireBase() {
        var catList = [Category]()
        guard let user = Auth.auth().currentUser else {
            return
        }
        self.ref.child("users").child(user.uid).child("userData").child("Categories").observe(.value, with: { (snapshot) in
            print("snapshot : ", snapshot)
            for item in 0..<snapshot.childrenCount {
                let cat = Category(context: self.context)
                cat.catName = snapshot.childSnapshot(forPath: String(item)).value as? String
                catList.append(cat)
            }
            print("LIST : ", catList)
        }, withCancel: nil)
    }
    
    func loadTodoItemsFromFireBase() {
        guard let user = Auth.auth().currentUser else {
            return
        }
        self.ref.child("users").child(user.uid).child("userData").child("TodoItems").observe(.value, with: { (snapshot) in
            
            for item in snapshot.children {
                                
                if let itemGuard = (item as? DataSnapshot)?.value as? NSMutableDictionary {
                    let id = itemGuard.value(forKey: "id") as? String
                    let category = itemGuard.value(forKey: "category") as? String
                    let date = itemGuard.value(forKey: "date") as? String
                    let summary = itemGuard.value(forKey: "summary") as? String
                    let title = itemGuard.value(forKey: "title") as? String
                    let checkmark = itemGuard.value(forKey: "checkmark") as? Bool
                    
                    if let potentiallyItem : TodoItem = self.getId(id: id) {
                        print("Load existing Item : ",potentiallyItem)
                    }
                    else {
                        ///////////////////////////////
                        let newItem = TodoItem.newTodoItem(context: self.context, id: id, title: title, category: category, checkmark: checkmark ?? false, date: date, image: nil, summary: summary)
                        //newItem.id = id
                        print("New Item fetch from FireBase", newItem)
                    }
                }
            }
            self.saveData()
        }, withCancel: nil)
    }
    
    func getId(id :String?) -> TodoItem? {
        var todoItem: TodoItem?
        guard let certifiedId : String = id else {
            return todoItem
        }
        let categoryRequest: NSFetchRequest<TodoItem> = NSFetchRequest<TodoItem>(entityName: "TodoItem")
        categoryRequest.predicate = NSPredicate(format: "id = %@", certifiedId)
        do {
            let fetchedResults = try self.context.fetch(categoryRequest)
            let results = fetchedResults as [NSManagedObject]
            if results.count > 0 {
                let updatedTodo = (results[0] as! TodoItem).toSerialized()
                if updatedTodo["id"] as? String == id {
                    todoItem = results[0] as? TodoItem
                }
            }
            
            print("TodoItem Load from FireBase", todoItem)
            
        } catch let error as NSError {
            print("Could not fetch : \(error)")
        }
        return todoItem
    }
}

extension Category {
    static func newCat(context : NSManagedObjectContext ,catName: String) -> Category {
        let id = NSUUID().uuidString
        let newCategory = Category(context: context)
        newCategory.catName = catName
        newCategory.id = id
        return newCategory
    }
    
    func toSerialized() -> [String:String?] {
        return ["id":self.id, "catName": self.catName]
    }
}

extension TodoItem {
    
    static func newTodoItem(context : NSManagedObjectContext, id: String? ,title: String?, category: String?, checkmark: Bool , date: String?, image: Data?, summary: String?) -> TodoItem {
        let safeId : String?
        if id == nil {
            safeId = NSUUID().uuidString
        } else {
            safeId = id
        }
        //let id = NSUUID().uuidString
        let NewTodoItem = TodoItem(context: context)
        NewTodoItem.id = safeId
        NewTodoItem.category = category
        NewTodoItem.checkmark = checkmark
        NewTodoItem.date = date
        NewTodoItem.title = title
        NewTodoItem.summary = summary
        NewTodoItem.image = image
        return NewTodoItem
    }
    
    func toSerialized() -> [String:Any?] {
        let boolCheckmark = self.checkmark ? 1 : 0
        return ["id":self.id, "title": self.title, "date": self.date, "summary": self.summary, "checkmark": boolCheckmark, "category": self.category]
    }
}
