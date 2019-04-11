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
            print("snapshot : ", snapshot.value)
            let dico = snapshot.value as! NSDictionary
            print("DICHOTOMY : ",dico)
//            for item in snapshot.children {
//                print("ITEM : ",item)
//                print(dico["\(item)"])
//                print("TEST : ", (snapshot.value as! NSDictionary)[item] )
//                //print("TEST 2 : ", snapshot.childSnapshot(forPath: String(item)).value)
//
//
//                let id = snapshot.childSnapshot(forPath: String(item)).childSnapshot(forPath: "id").value as? String
//                let category = snapshot.childSnapshot(forPath: String(item)).childSnapshot(forPath: "category").value as? String
//                let checkmark = snapshot.childSnapshot(forPath: String(item)).childSnapshot(forPath: "checkmark").value as? Bool
//                let date = snapshot.childSnapshot(forPath: String(item)).childSnapshot(forPath: "date").value as? String
//                let summary = snapshot.childSnapshot(forPath: String(item)).childSnapshot(forPath: "summary").value as? String
//                let title = snapshot.childSnapshot(forPath: String(item)).childSnapshot(forPath: "title").value as? String
//
//                print("ID !!!! ", id)
//
//                if let potentiallyItem = self.getId(id: id) {
//                    print("Load existing Item : ",potentiallyItem)
//                } else {
//                    let newItem = TodoItem.newTodoItem(context: self.context, title: title, category: category, checkmark: checkmark ?? false, date: date, image: nil, summary: summary)
//                    print("New Item fetch from FireBase", newItem)
//                }
//            }
            
        }, withCancel: nil)
    }
    
    func getId(id :String?) -> TodoItem? {
        var todoItem: TodoItem?
        guard let certifiedId : String = id else {
            return todoItem
        }
        let categoryRequest: NSFetchRequest<TodoItem> = NSFetchRequest<TodoItem>(entityName: "TodoItem")
        categoryRequest.predicate = NSPredicate(format: "id contains[c] %@", certifiedId)
        do {
            let fetchedResults = try self.context.fetch(categoryRequest)
            let results = fetchedResults as [NSManagedObject]
            
            guard let user = Auth.auth().currentUser else {
                return todoItem
            }
            
            for item in results {
                //let updatedCat = (item as! TodoItem).toSerialized()
                self.ref.child("users").child(user.uid).child("userData").child("TodoItems").child((item as! TodoItem).id!).observeSingleEvent(of: .value) { (snapshot) in
                    todoItem = snapshot.value as? TodoItem ?? nil
                }
            }
            print("TodoItem Load from FireBase")
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
    
    static func newTodoItem(context : NSManagedObjectContext ,title: String?, category: String?, checkmark: Bool , date: String?, image: Data?, summary: String?) -> TodoItem {
        let id = NSUUID().uuidString
        let NewTodoItem = TodoItem(context: context)
        NewTodoItem.id = id
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
