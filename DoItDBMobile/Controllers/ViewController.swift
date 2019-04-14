//
//  ViewController.swift
//  DoItDBMobile
//
//  Created by MALOSSE Maxime on 22/02/2019.
//  Copyright © 2019 MALOSSE Maxime. All rights reserved.
//

import UIKit
import CoreData
import Firebase
import IQKeyboardManagerSwift

class ViewController: UIViewController {
    
    //MARK: - Vars and IBOutlets
    var navigationBar: UINavigationBar!
    var items = [TodoItem]()
    let context = DataManager.SharedDataManager.context
    let dataManager = DataManager.SharedDataManager
    var filteredItems = [TodoItem]()
    var isFiltered = false
    var categories = [Category]()
    
    var ref = Database.database().reference()
    var sortedBy = SortedBy.categorie
    let orderByAZ = ["A", "B", "C", "D", "E", "F", "G", "H", "I", "J", "K", "L", "M", "N", "O", "P", "Q", "R", "S", "T", "U", "V", "W", "X", "Y", "Z", "Other"]
    let alphabeticArray = ["A", "B", "C", "D", "E", "F", "G", "H", "I", "J", "K", "L", "M", "N", "O", "P", "Q", "R", "S", "T", "U", "V", "W", "X", "Y", "Z"]
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var searchBar: UISearchBar!
    
    //MARK: - ViewWilAppear
    override func viewWillAppear(_ animated: Bool) {
        saveItems()
    }
    
    //MARK: - ViewDidLoad
    override func viewDidLoad() {
        super.viewDidLoad()
        listToDisplaySorted()
        searchBar.delegate = self
        if(self.categories.count == 0) {
            saveItems()
        }
    }
    
    @IBAction func logout() {
        do {
            try Auth.auth().signOut()
            
        } catch let error {
            print(error)
        }
        self.dismiss(animated: true, completion: nil)
        
    }
    
    //MARK: - Init()
    required init?(coder aDecoder: NSCoder) {
        super.init(coder : aDecoder)
        dataManager.loadTodoItemsFromFireBase()
        dataManager.loadCatFromFireBase()
        loadItems()
    }
    
    
    //MARK:- prepare for segue
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let indexPath = (tableView.indexPath(for: sender as! UITableViewCell))!
        if segue.identifier == "editItem"
        {
            let destVC = segue.destination as! EditItemViewController
            var itemToUpdate: TodoItem
            
            if(isFiltered){
                itemToUpdate = items.filter{$0 === filteredItems[indexPath.row]}[0]
            } else {
                var tempTable = tempTableOrder(pathSection: indexPath.section)
                let index = items.firstIndex{$0 == tempTable[indexPath.row]}
                itemToUpdate = items[index!]
            }
            destVC.newItem = itemToUpdate
            destVC.delegate = self
        }
    }
    
    //MARK:- Fonction relative à la gestion de la table
    func deleteRowByTitle(title: String?, index: Int){
        let request = NSFetchRequest<TodoItem>(entityName: "TodoItem")
        request.predicate = NSPredicate(format: "title = %@", title ?? "")
        do {
            let result = try self.context.fetch(request)
            items.remove(at: index)
            for item in result {
                dataManager.deleteTodoItemsFromFireBase(todoItem: item)
                context.delete(item)
            }
        } catch let error as NSError {
            print("error : \(error)")
        }
    }
    
    func listToDisplaySorted(){
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd MMM yy"
        dateFormatter.timeZone = TimeZone.autoupdatingCurrent
        self.loadItems()
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .none
        dateFormatter.locale = Locale(identifier: "fr_FR")
        
        switch self.sortedBy {
        case .alphabetique:
            items = items.sorted { $0.title!.lowercased() < $1.title!.lowercased() }
        case .date:
            items = items.sorted{dateFormatter.date(from: $0.date ?? "01 Janv. 2099") as Date! < dateFormatter.date(from: $1.date ?? "01 Janv. 2099") as Date!}
        default:
            categories = categories.sorted{$0.catName!.lowercased() < $1.catName!.lowercased()}
        }
        self.tableView.reloadData()
    }
    
    //MARK:- Actions
    @IBAction func addItem(_ sender: UIBarButtonItem) {
        
        let alertController = UIAlertController(title: "ToDo", message: "New Item / Category", preferredStyle: .alert)
        
        let addTask = UIAlertAction(title: "Ajouter une tâche", style: .default) { (action) in
            let tf = alertController.textFields?[0]
            
            let newItemTitle = tf!.text!
            
            let newItem = TodoItem.newTodoItem(context: self.context, id: nil, title: newItemTitle, category: nil, checkmark: false, date: nil, image: nil, summary: nil)
            self.items.append(newItem)
            if self.isFiltered {
                self.filteredItems.append(newItem)
                self.tableView.insertRows(at: [IndexPath(item: self.filteredItems.count - 1, section: 0)], with: .automatic)
            }
            self.tableView.reloadData()
            self.saveItems()
        }
        
        let addCat = UIAlertAction(title: "Ajouter une catégorie", style: .default) { (action) in
            let tf = alertController.textFields?[0]
            let newTask = tf!.text!
            let newItem = Category.newCat(context: self.context, catName: newTask, id:nil)
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
    func loadFromFirebase() {
        let ref = Database.database().reference()
        let user = Auth.auth().currentUser
        print(ref.child("users").child(user!.uid).child("userData").child("TodoItems"))
    }
    
    
    func saveItems() {
        do {
            try self.context.save()
            dataManager.saveFireBase()
        } catch let error as NSError {
            print("Could not save data -> error : \(error)")
        }
    }
    
    func loadItems() {
        let fetchRequestCat: NSFetchRequest<Category> = NSFetchRequest<Category>(entityName: "Category")
        categories.removeAll(keepingCapacity: false)
        categories = loadGenericCategoryItems(list: categories, request: fetchRequestCat)
        
        let fetchRequest: NSFetchRequest<TodoItem> = NSFetchRequest<TodoItem>(entityName: "TodoItem")
        items.removeAll(keepingCapacity: false)
        items = loadGenericTodoItems(list: items, request: fetchRequest)
    }
    
    //MARK: - Load items Methods
    func loadGenericTodoItems(list : [TodoItem], request: NSFetchRequest<TodoItem> ) -> [TodoItem] {
        var resultList = list
        do {
            let fetchedResults = try self.context.fetch(request)
            let results = fetchedResults as [NSManagedObject]
            
            for item in results {
                print("item load: ", item)
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
    
    //Permet de récuperer les tables à afficher par par section
    func tempTableOrder(pathSection : Int) -> [TodoItem]{
        var tempTable = [TodoItem]()
        switch sortedBy {
        case .alphabetique:
            if(orderByAZ[pathSection] == "Other"){
                tempTable = items.filter{!alphabeticArray.contains(($0.title?.first?.uppercased())!)}
            }else{
                tempTable = items.filter{$0.title?.first?.uppercased() == orderByAZ[pathSection]}
            }
        case .date:
            tempTable = items
        default:
            if(pathSection >= categories.count){
                tempTable = items.filter{$0.category == nil}
            }else{
                tempTable = items.filter{$0.category == categories[pathSection].catName};
            }
        }
        return tempTable
    }
}

//MARK: - Table view
extension ViewController : UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        let title : String
        switch sortedBy {
        case .alphabetique:
            title = orderByAZ[section]
        case .date:
            title = "Date"
        default:
            if(section >= categories.count){
                title = "a catégoriser"
            }else{
                title = categories[section].catName ?? ""
            }
        }
        return isFiltered ? "Resultat de la recherche : " : title
    }
    func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        if let headerView = view as? UITableViewHeaderFooterView {
            headerView.textLabel?.textAlignment = .center
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let tempTable = tempTableOrder(pathSection: section)
        return isFiltered ? filteredItems.count : tempTable.count
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        let numberOfSection : Int;
        switch sortedBy {
        case .alphabetique:
            numberOfSection = orderByAZ.count
        case .date:
            numberOfSection = 1
        default:
            numberOfSection = categories.count+1
        }
        return isFiltered ? 1 : numberOfSection
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cellidentifier") as! CheckItemTableViewCell
        let tempTable = tempTableOrder(pathSection: indexPath.section)
        let task = isFiltered ? filteredItems[indexPath.row] : tempTable[indexPath.row]
        cell.cellTextField.text = task.title
        cell.checkmark.isHidden = !task.checkmark
        cell.summaryLabel.text = task.summary
        cell.dateLabel.text = task.date
        
        if let imageData: Data = try task.image {
            let realImage = Data(base64Encoded: imageData)!
            cell.cellImage.image = UIImage(data: realImage)
        } else {
            cell.cellImage.image = UIImage(named: "imagePickerIcone.png")
        }
        
        return cell
    }
    
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        searchBar.resignFirstResponder()
        if(isFiltered) {
            filteredItems[indexPath.row].checkmark = !filteredItems[indexPath.row].checkmark
        } else {
            var tempTable = tempTableOrder(pathSection: indexPath.section)
            let index = items.firstIndex{$0 == tempTable[indexPath.item]}!
            items[index].checkmark = !items[index].checkmark
        }
        tableView.deselectRow(at: indexPath, animated: true)
        tableView.reloadData()
        saveItems()
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        let index : Int;
        if (editingStyle == .delete) {
            if isFiltered
            {
                index = items.firstIndex{$0 == filteredItems[indexPath.item]}!
                filteredItems.remove(at: indexPath.row)
            } else {
                var tempTable = tempTableOrder(pathSection: indexPath.section)
                index = items.firstIndex{$0 == tempTable[indexPath.row]}!
                //tempTable = loadGenericTodoItems(list: tempTable, request: fetchRequest)
            }
            deleteRowByTitle(title: items[index].title, index: index)
            tableView.deleteRows(at: [indexPath], with: .automatic)
            tableView.reloadData()
            saveItems()
        }
    }
}

//MARK: - SearchBar
extension ViewController : UISearchBarDelegate {
    
    func searchBar(_ searchBar: UISearchBar, selectedScopeButtonIndexDidChange selectedScope: Int) {
        switch selectedScope {
        case 1:
            sortedBy = .alphabetique
        case 2:
            sortedBy = .date
        default:
            sortedBy = .categorie
        }
        listToDisplaySorted()
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        if (searchBar.text?.count==0) {
            isFiltered = false
            tableView.reloadData()
        } else {
            filteredItems = []
            isFiltered = true
            let fetchRequest: NSFetchRequest<TodoItem> = NSFetchRequest<TodoItem>(entityName: "TodoItem")
            fetchRequest.predicate = NSPredicate(format: "title contains[cd] %@", searchText)
            self.filteredItems = loadGenericTodoItems(list: self.filteredItems, request: fetchRequest)
            self.tableView.reloadData()
        }
    }
    
    
    func searchBarTextDidEndEditing(_ searchBar: UISearchBar) {
        if (searchBar.text?.count == 0) {
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

