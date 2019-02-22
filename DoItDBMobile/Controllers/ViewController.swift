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
    
    static var documentDirectory : URL {
        return FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }
    
    static var dataFileUrl : URL {
        return documentDirectory.appendingPathComponent("Checklists").appendingPathExtension("json")
    }
    
    var items = [TodoItem]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
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
            destVC.newItem = items[(tableView.indexPath(for: sender as! UITableViewCell)?.row)!]
        }
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
        
        return items.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cellidentifier") as! CheckItemTableViewCell
        cell.cellTextField.text = items[indexPath.row].title
        cell.checkmark.isHidden = !items[indexPath.row].checked
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        items[indexPath.row].toggle()
        tableView.reloadRows(at: [indexPath], with: .automatic)
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        
        if (editingStyle == .delete) {
            items.remove(at: indexPath.item)
            tableView.deleteRows(at: [indexPath], with: .automatic)
        }
        
    }
    
}
