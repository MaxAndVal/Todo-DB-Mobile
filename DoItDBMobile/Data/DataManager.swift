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
            var i = 0
            for item in results {
                
                let keys = Array(item.entity.attributesByName.keys)
                var newData : [String:String] = [:]
                
                
                for key in keys {
                    newData.updateValue(item.primitiveValue(forKey: key) as? String ?? "", forKey: key)
                }
                
                guard let user = Auth.auth().currentUser else {
                    return
                }
                self.ref.child("users").child(user.uid).child("userData").child("TodoItems").child("\(item.primitiveValue(forKey: "id") ?? "\(i)" )").updateChildValues(newData)
                
                i += 1
                
            }
            print("TodoItems saved to Firebase")
        } catch let error as NSError {
            print("Could not fetch : \(error)")
        }
        
        let categoryRequest: NSFetchRequest<Category> = NSFetchRequest<Category>(entityName: "Category")
        
        
        var resultList = [Category]()
        do {
            let fetchedResults = try self.context.fetch(categoryRequest)
            let results = fetchedResults as [NSManagedObject]
            
            guard let user = Auth.auth().currentUser else {
                return
            }
            
            for item in results {
                resultList.append(item as! Category)
                let updatedCat = (item as! Category).toSerialized()
                print("UpdateCat : ",updatedCat)
                self.ref.child("users").child(user.uid).child("userData").child("Categories").child((item as! Category).id!).updateChildValues(updatedCat)
            }
            
        } catch let error as NSError {
            print("Could not fetch : \(error)")
        }
        
        // TODO : to solve
//        do {
//            let fetchedResults = try self.context.fetch(categoryRequest)
//            let results = fetchedResults as [NSManagedObject]
//            var i = 0
//            var newData : [String:String] = [:]
//            var newArray = [String]()
//            for item in results {
//                let keys = Array(item.entity.attributesByName.keys)
//
//                for key in keys {
//                    newArray.append(item.primitiveValue(forKey: key) as! String)
//                }
//            }
//            newArray = newArray.filter({ (value) -> Bool in
//                value != "none"
//            })
//            newArray.append("none")
//            print("newArray = ", newArray)
//            var tupleArray = [(String, String)]()
//            for item in newArray {
//                tupleArray.append((String(i), item))
//                i += 1
//            }
//            newData.merge(tupleArray) { (current, _) in current }
//
//            print("Category new : ",newData)
//
//            guard let user = Auth.auth().currentUser else {
//                return
//            }
//            self.ref.child("users").child(user.uid).child("userData").child("Categories").updateChildValues(newData)
//
//            let catRef = self.ref.child("users").child(user.uid).child("userData").child("Categories").childByAutoId()
//            catRef.setValue(newData) { (error, dataBaseRef) in
//                if error != nil {
//                    print(error!)
//                    return
//                }
//                // TODD : add an ID for Category and TodoItems Entities
//                //cate.id = catRef.key
//            }
//
//        } catch let error as NSError {
//            print("Could not fetch : \(error)")
//        }
    }
    
    func loadCatFromFireBase() {
        var catList = [Category]()
        guard let user = Auth.auth().currentUser else {
            return
        }
        self.ref.child("users").child(user.uid).child("userData").child("Categories").observe(.value, with: { (snapshot) in
            print("snapshot : ", snapshot)
            for item in 0..<snapshot.childrenCount {
                if let itemId = snapshot.childSnapshot(forPath: "id").value as? String {
                    
                }
                let cat = Category(context: self.context)
                cat.catName = snapshot.childSnapshot(forPath: String(item)).value as? String
                catList.append(cat)
            }
            print("LIST : ", catList)
        }, withCancel: nil)
    }
    
    func loadTodoItemsFromFireBase() {
        var todoList = [TodoItem]()
        guard let user = Auth.auth().currentUser else {
            return
        }
        self.ref.child("users").child(user.uid).child("userData").child("TodoItems").observe(.value, with: { (snapshot) in
            print("snapshot : ", snapshot)
            for item in 0..<snapshot.childrenCount {
                let todoItem = TodoItem(context: self.context)
                let category = snapshot.childSnapshot(forPath: String(item)).childSnapshot(forPath: "category").value as? String
                let checkmark = snapshot.childSnapshot(forPath: String(item)).childSnapshot(forPath: "checkmark").value as? Bool
                let date = snapshot.childSnapshot(forPath: String(item)).childSnapshot(forPath: "date").value as? String
                let summary = snapshot.childSnapshot(forPath: String(item)).childSnapshot(forPath: "summary").value as? String
                let title = snapshot.childSnapshot(forPath: String(item)).childSnapshot(forPath: "title").value as? String
                todoItem.category = category
                todoItem.title = title
                todoItem.checkmark = checkmark ?? false
                todoItem.date = date
                todoItem.summary = summary
                todoList.append(todoItem)
            }
            print("LIST : ", todoList)
        }, withCancel: nil)
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
    
    static func newTodoItem(context : NSManagedObjectContext ,title: String?, category: String?, checkmark: Bool = false, date: String?, image: Data?, summary: String?) -> TodoItem {
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
        return ["id":self.id, "title": self.title, "date": self.date, "summary": self.summary, "checkmark": self.checkmark, "category": self.category]
    }
}
