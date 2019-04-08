//
//  ViewController.swift
//  DoItDBMobile
//
//  Created by MALOSSE Maxime on 22/02/2019.
//  Copyright © 2019 MALOSSE Maxime. All rights reserved.
//

import UIKit
import CoreData

class ViewController: UIViewController {
    
    //MARK : - Vars and IBOutlets
    var navigationBar: UINavigationBar!
    var items = [TodoItem]()
    let context = DataManager.SharedDataManager.context
    let dataManager = DataManager.SharedDataManager
    var filteredItems = [TodoItem]()
    var isFiltered = false
    //var listToDisplay = [TodoItem]()
    var categories = [Category]()
    var sortedBy = SortedBy.categorie
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var searchBar: UISearchBar!
    
    //MARK : - ViewWilAppear
    override func viewWillAppear(_ animated: Bool) {
        saveItems()
    }
    
    //MARK : - ViewDidLoad
    override func viewDidLoad() {
        super.viewDidLoad()
        searchBar.delegate = self
        if(self.categories.count == 0) {
            let initCat = Category(context: context)
            initCat.catName = "none"
            self.categories.append(initCat)
            saveItems()
        }
    }
    
    //MARK : - Init()
    required init?(coder aDecoder: NSCoder) {
        super.init(coder : aDecoder)
        loadItems()
    }
    

    //MARK:- prepare for segue
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "editItem"
        {
            let destVC = segue.destination as! EditItemViewController
            var itemToUpdate: TodoItem
            
            if(isFiltered){
                itemToUpdate = items.filter{$0 === filteredItems[(tableView.indexPath(for: sender as! UITableViewCell)?.row)!]}[0]
            } else {
                let section = (tableView.indexPath(for: sender as! UITableViewCell)?.section)!
                var tempTable = tempTableByCat(category: categories[section].catName!)
                
                itemToUpdate = tempTable[(tableView.indexPath(for: sender as! UITableViewCell)?.row)!]
            }
            destVC.newItem = itemToUpdate
            destVC.delegate = self
        }
    }
    
    
    //MARK : - TempTable by Category
    func tempTableByCat(category : String = "none") -> [TodoItem] {
        let tempTable = [TodoItem]()
        
        let fetchRequest: NSFetchRequest<TodoItem> = NSFetchRequest<TodoItem>(entityName: "TodoItem")
        
        fetchRequest.predicate = NSPredicate(format: "category contains[c] %@", category)
        switch sortedBy {
        case .alphabetique:
            listToDisplaySorted(type : .alphabetique)
            tableView.reloadData()
        case .date:
            print("2")
            listToDisplaySorted(type : .date)
            tableView.reloadData()
        default:
            listToDisplaySorted(type : .categorie)
            tableView.reloadData()
        }
        return loadGenericTodoItems(list: tempTable, request: fetchRequest)

    }
    
    func deleteRowByTitle(title: String?, index: Int){
        let request = NSFetchRequest<TodoItem>(entityName: "TodoItem")
        request.predicate = NSPredicate(format: "title = %@", title ?? "")
        do {
            let result = try self.context.fetch(request)
            items.remove(at: index)
            for item in result {
                context.delete(item)
            }
        } catch let error as NSError {
            print("error : \(error)")
        }
    }
    
    func listToDisplaySorted(type : SortedBy){
        switch type {
        case .alphabetique:
             sortedBy = .alphabetique
            self.isFiltered ? filteredItems.sorted { $0.title!.lowercased() < $1.title!.lowercased() } :  items.sorted { $0.title!.lowercased() < $1.title!.lowercased() }
        case .date:
             sortedBy = .date
            //self.listToDisplay = self.isFiltered ? filteredItems.sorted { $0.date < $1.date } :  items.sorted { $0.date < $1.date }
            print("pouet")
        default:
             sortedBy = .categorie
        }
        
    }
    
    //MARK:- Actions
    @IBAction func addItem(_ sender: UIBarButtonItem) {
        
        let alertController = UIAlertController(title: "ToDo", message: "New Item / Category", preferredStyle: .alert)
        
        let addTask = UIAlertAction(title: "Ajouter une tâche", style: .default) { (action) in
            let tf = alertController.textFields?[0]
            
            let newItemTitle = tf!.text!
            
            let newItem = TodoItem(context: self.context)
            newItem.checkmark = false
            newItem.title = newItemTitle
            newItem.category = "none"
            self.items.append(newItem)
            let tempTable = self.tempTableByCat(category: "none")
            if self.isFiltered {
                self.filteredItems.append(newItem)
                self.tableView.insertRows(at: [IndexPath(item: self.filteredItems.count - 1, section: 0)], with: .automatic)
            } else {
                self.tableView.insertRows(at: [IndexPath(item: tempTable.count - 1, section: 0)], with: .automatic)
            }
            self.tableView.reloadData()
            self.saveItems()
            self.dataManager.saveFireBase()
        }
        
        let addCat = UIAlertAction(title: "Ajouter une catégorie", style: .default) { (action) in
            let tf = alertController.textFields?[0]
            let newTask = tf!.text!
            let newItem = Category(context: self.context)
            newItem.catName = newTask
            self.categories.append(newItem)
            self.tableView.reloadData()
            self.saveItems()
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
        
        alertController.addAction(addTask)
        alertController.addAction(addCat)
        alertController.addAction(cancelAction)
        
        addTask.isEnabled = false
        addCat.isEnabled = false
        
        alertController.addTextField { (textField) in
            
            NotificationCenter.default.addObserver(forName: UITextField.textDidChangeNotification, object: textField, queue: OperationQueue.main, using:
                {_ in
                    textField.placeholder = "titre ..."
                    let textCount = textField.text?.count ?? 0
                    let textIsNotEmpty = textCount > 0
                    
                    addTask.isEnabled = textIsNotEmpty
                    addCat.isEnabled = textIsNotEmpty
                    
            })
        }
        present(alertController, animated: true)
    }
    
    //MARK: - Save and Load Data
    func saveItems() {
        do {
            try self.context.save()
        } catch let error as NSError {
            print("Could not save data -> error : \(error)")
        }
    }
    
    func loadItems() {
        let fetchRequest: NSFetchRequest<TodoItem> = NSFetchRequest<TodoItem>(entityName: "TodoItem")
        items = loadGenericTodoItems(list: items, request: fetchRequest)

        let fetchRequestCat: NSFetchRequest<Category> = NSFetchRequest<Category>(entityName: "Category")
        categories = loadGenericCategoryItems(list: categories, request: fetchRequestCat)
    }
    
    //MARK : - Load items Methods
    func loadGenericTodoItems(list : [TodoItem], request: NSFetchRequest<TodoItem> ) -> [TodoItem] {
        var resultList = list
        do {
            let fetchedResults = try self.context.fetch(request)
            let results = fetchedResults as [NSManagedObject]
            
            for item in results {
                resultList.append(item as! TodoItem)
            }
        } catch let error as NSError {
            print("Could not fetch : \(error)")
        }
        return resultList
    }
    
    func loadGenericCategoryItems(list : [Category] , request: NSFetchRequest<Category> ) -> [Category] {
        var resultList = list
        do {
            let fetchedResults = try self.context.fetch(request)
            let results = fetchedResults as [NSManagedObject]
            
            for item in results {
                resultList.append(item as! Category)
            }
        } catch let error as NSError {
            print("Could not fetch : \(error)")
        }
        return resultList
    }
    
}

//MARK: - Table view
extension ViewController : UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        let title : String
        switch sortedBy {
        case .alphabetique:
            title = "A-z"
        case .date:
            title = "Date"
        default:
            title = categories[section].catName ?? ""
        }
        
        return isFiltered ? "Resultat de la recherche : " : title
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let tempTable = tempTableByCat(category: categories[section].catName!)
        return isFiltered ? filteredItems.count : tempTable.count
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return isFiltered || sortedBy != .categorie ? 1 : categories.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cellidentifier") as! CheckItemTableViewCell
        let task = isFiltered ? filteredItems[indexPath.row] : items[indexPath.row]
        
        cell.cellTextField.text = task.title
        cell.checkmark.isHidden = !task.checkmark
        cell.summaryLabel.text = task.summary
        if let imageData: Data = try task.image {
            let realImage = Data(base64Encoded: imageData)!
            cell.cellImage.image = UIImage(data: realImage)
        } else {
            cell.cellImage.image = UIImage(named: "imagePickerIcone.png")
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        if(isFiltered) {
            filteredItems[indexPath.row].checkmark = !filteredItems[indexPath.row].checkmark
        } else {
            var tempTable = tempTableByCat(category: categories[indexPath.section].catName!)
            tempTable[indexPath.row].checkmark = !tempTable[indexPath.row].checkmark
        }
        tableView.deselectRow(at: indexPath, animated: true)
        tableView.reloadData()
        saveItems()
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        
        if (editingStyle == .delete) {
            if isFiltered
            {
                let index = items.firstIndex{$0 == filteredItems[indexPath.item]}
                filteredItems.remove(at: indexPath.row)
                deleteRowByTitle(title: items[index!].title, index: index!)
            } else {
                var tempTable = tempTableByCat(category: categories[indexPath.section].catName!)
                let index = items.firstIndex{$0 == tempTable[indexPath.row]} ?? -1
                deleteRowByTitle(title: items[index].title, index : index)
            }
            tableView.deleteRows(at: [indexPath], with: .automatic)
            tableView.reloadData()
            saveItems()
        }
    }
}

//MARK : - SearchBar
extension ViewController : UISearchBarDelegate {
    
    func searchBar(_ searchBar: UISearchBar, selectedScopeButtonIndexDidChange selectedScope: Int) {
        switch selectedScope {
        case 1:
            listToDisplaySorted(type : .alphabetique)
            tableView.reloadData()
        case 2:
            print("2")
            listToDisplaySorted(type : .date)
            tableView.reloadData()
        default:
            listToDisplaySorted(type : .categorie)
            tableView.reloadData()
        }
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        if (searchBar.text?.count==0) {
            isFiltered = false
            tableView.reloadData()
        } else {
            filteredItems = []
            isFiltered = true
            let fetchRequest: NSFetchRequest<TodoItem> = NSFetchRequest<TodoItem>(entityName: "TodoItem")
            fetchRequest.predicate = NSPredicate(format: "title contains[c] %@", searchText)
            self.filteredItems = loadGenericTodoItems(list: self.filteredItems, request: fetchRequest)
            self.tableView.reloadData()
        }
    }
    
    
    func searchBarTextDidEndEditing(_ searchBar: UISearchBar) {
        print("searchBarTextDidEndEditing")
        if (searchBar.text?.count==0) {
            isFiltered = false
            tableView.reloadData()
        } else {
            filteredItems = []
            isFiltered = true
            
            let fetchRequest: NSFetchRequest<TodoItem> = NSFetchRequest<TodoItem>(entityName: "TodoItem")
            fetchRequest.predicate = NSPredicate(format: "title contains[c] %@", self.searchBar.text ?? "")
            self.filteredItems = loadGenericTodoItems(list: self.filteredItems, request: fetchRequest)
            self.tableView.reloadData()
        }
    }
}

extension ViewController : EditItemControllerDelegate {
    
    func didFinishEditItem(controller: ViewController, item: TodoItem) {
        controller.tableView.reloadData()
        controller.searchBarTextDidEndEditing(controller.searchBar)
        navigationController?.popViewController(animated: true)
    }
}

