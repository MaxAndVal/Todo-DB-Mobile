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
    
    @IBOutlet weak var navigationBar: UINavigationBar!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var searchBar: UISearchBar!
    var items = [TodoItem]()
    let context = DataManager.SharedDataManager.context
    var filteredItems = [TodoItem]()
    var isFiltered = false
    var categories = [Category]()
    var sections = [[TodoItem]()]
    
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
    required init?(coder aDecoder: NSCoder) {
        super.init(coder : aDecoder)
        loadItems()
    }
    
    //MARK:- prepare
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "editItem"
        {
            let destVC = segue.destination as! EditItemViewController
            var itemToUpdate:TodoItem
            
            if(isFiltered){
                //let test = filteredItems[(tableView.indexPath(for: sender as! UITableViewCell)?.row)!]
                itemToUpdate = items.filter{$0 === filteredItems[(tableView.indexPath(for: sender as! UITableViewCell)?.row)!]}[0]
            }else{
                itemToUpdate = items[(tableView.indexPath(for: sender as! UITableViewCell)?.row)!]
            }
            destVC.newItem = itemToUpdate
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        saveItems()
    }
    
    //MARK:- Actions
    @IBAction func addItem(_ sender: UIBarButtonItem) {
        
        let alertController = UIAlertController(title: "ToDo", message: "New Item ?", preferredStyle: .alert)
        
        let okAction = UIAlertAction(title: "OK", style: .default) { (action) in
            let tf = alertController.textFields?[0]
            var newItemTitle = tf!.text!
            if (newItemTitle == "") {
                newItemTitle = "newItem \(self.items.count + 1)"
            }
            let newItem = TodoItem(context: self.context)
            newItem.checkmark = false
            newItem.title = newItemTitle
            self.items.append(newItem)
            if self.isFiltered
            {
                self.filteredItems.append(newItem)
                self.tableView.insertRows(at: [IndexPath(item: self.filteredItems.count - 1, section: 0)], with: .automatic)
            }else{
                self.tableView.insertRows(at: [IndexPath(item: self.items.count - 1, section: 0)], with: .automatic)
            }
            
            self.saveItems()
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
        
        alertController.addTextField { (textField) in
            textField.placeholder = "titre ..."
        }
        
        alertController.addAction(okAction)
        alertController.addAction(cancelAction)
        present(alertController, animated: true)
        
    }
    
    func saveItems() {
        do {
            try self.context.save()
        } catch let error as NSError {
            print("Could not save data -> error : \(error)")
        }
    }
    
    func loadItems() {
        let fetchRequest: NSFetchRequest<TodoItem> = NSFetchRequest<TodoItem>(entityName: "TodoItem")
        do {
            let fetchedResults = try self.context.fetch(fetchRequest)
            let results = fetchedResults as [NSManagedObject]
            
            for item in results {
                items.append(item as! TodoItem)
            }
            //items = results as! [TodoItem]
        } catch let error as NSError {
            print("Could not fetch : \(error)")
        }
        
    }
    
    @IBAction func editItem() {
        
    }
    
    
    
    //MARK:- View Setup
    // not used
    func setupConstraints() {
        navigationBar.translatesAutoresizingMaskIntoConstraints = false
        navigationBar.heightAnchor.constraint(equalToConstant: 44).isActive = true
        navigationBar.leftAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leftAnchor).isActive = true
        navigationBar.rightAnchor.constraint(equalTo: view.safeAreaLayoutGuide.rightAnchor).isActive = true
        navigationBar.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor).isActive = true
    }
    
}

extension ViewController : UITableViewDelegate, UITableViewDataSource {
    
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return isFiltered ? filteredItems.count : items.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cellidentifier") as! CheckItemTableViewCell
        cell.cellTextField.text = isFiltered ? filteredItems[indexPath.row].title : items[indexPath.row].title
        cell.checkmark.isHidden = isFiltered ? !filteredItems[indexPath.row].checkmark : !items[indexPath.row].checkmark
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if(isFiltered) {
            filteredItems[indexPath.row].checkmark = !filteredItems[indexPath.row].checkmark
            
        }else{
            items[indexPath.row].checkmark = !items[indexPath.row].checkmark
            
        }
        tableView.reloadRows(at: [indexPath], with: .automatic)
        tableView.deselectRow(at: indexPath, animated: true)
        saveItems()
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        
        if (editingStyle == .delete) {
            if isFiltered
            {
                items = items.filter{$0 !== filteredItems[indexPath.item]}
                filteredItems.remove(at: indexPath.item)
            }
            else{
                items.remove(at: indexPath.item)
            }
            tableView.deleteRows(at: [indexPath], with: .automatic)
            saveItems()
        }
    }
}

extension ViewController : UISearchBarDelegate {
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        if(searchBar.text?.count==0){
            isFiltered = false
            tableView.reloadData()
        }else{
            isFiltered = true
            filteredItems = items.filter { $0.title!.lowercased().contains(searchBar.text!.lowercased()) }
            tableView.reloadData()
        }
    }
    func searchBarTextDidEndEditing(_ searchBar: UISearchBar) {
        if(searchBar.text?.count==0){
            isFiltered = false
            tableView.reloadData()
        }else{
            isFiltered = true
            filteredItems = items.filter { $0.title!.lowercased().contains(searchBar.text!.lowercased()) }
            tableView.reloadData()
        }
    }
}

