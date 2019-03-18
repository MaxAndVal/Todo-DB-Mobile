//
//  ViewController.swift
//  DoItDBMobile
//
//  Created by MALOSSE Maxime on 22/02/2019.
//  Copyright © 2019 MALOSSE Maxime. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
    
    @IBOutlet weak var navigationBar: UINavigationBar!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var searchBar: UISearchBar!
    var items = [TodoItem]()
    var filteredItems = [TodoItem]()
    var isFiltered = false
    
    
    
    static var documentDirectory : URL {
        return FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }
    
    
    static var dataFileUrl : URL {
        return documentDirectory.appendingPathComponent("Checklists").appendingPathExtension("json")
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        searchBar.delegate = self
        // Do any additional setup after loading the view, typically from a nib.
        
        
    }
    required init?(coder aDecoder: NSCoder) {
        super.init(coder : aDecoder)
        loadTodoList()
    }
    
    //MARK:- prepare
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "editItem"
        {
            let destVC = segue.destination as! EditItemViewController
            var itemToUpdate:TodoItem
            
            if(isFiltered){
                let test = filteredItems[(tableView.indexPath(for: sender as! UITableViewCell)?.row)!]
                itemToUpdate = items.filter{$0 === test}[0]
            }else{
                itemToUpdate = items[(tableView.indexPath(for: sender as! UITableViewCell)?.row)!]
            }
            destVC.newItem = itemToUpdate
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        savetodoList()
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
            self.items.append(TodoItem(title: newItemTitle, checkmark: false))
            self.tableView.insertRows(at: [IndexPath(item: self.items.count - 1, section: 0)], with: .automatic)
            self.savetodoList()
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
        
        alertController.addTextField { (textField) in
            textField.placeholder = "titre ..."
        }
        
        alertController.addAction(okAction)
        alertController.addAction(cancelAction)
        present(alertController, animated: true)
        
    }
    
    func savetodoList(){
        print("save todo")
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        do {
            let data = try encoder.encode(items)
            try data.write(to: ViewController.dataFileUrl)
            print(String(data: data, encoding: .utf8)!)
        } catch {
            print(error)
        }
    }
    func loadTodoList(){
        print("is loading")
        let decoder = JSONDecoder()
        do {
            let data = try Data(contentsOf: ViewController.dataFileUrl)
            items = try decoder.decode([TodoItem].self, from: data)
        } catch {
            print(error)
            
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
        cell.checkmark.isHidden = isFiltered ? !filteredItems[indexPath.row].checked : !items[indexPath.row].checked
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        items[indexPath.row].toggle()
        tableView.reloadRows(at: [indexPath], with: .automatic)
        tableView.deselectRow(at: indexPath, animated: true)
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
            savetodoList()
        }
    }
}

extension ViewController : UISearchBarDelegate {
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        if(searchBar.text?.count==0){
            print("empty")
            isFiltered = false
            tableView.reloadData()
        }else{
            isFiltered = true
            filteredItems = items.filter { $0.title.lowercased().contains(searchBar.text!.lowercased()) }
            tableView.reloadData()
        }
    }
}

