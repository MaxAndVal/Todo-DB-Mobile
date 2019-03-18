//
//  EditItemViewController.swift
//  DoItDBMobile
//
//  Created by MALOSSE Maxime on 22/02/2019.
//  Copyright © 2019 MALOSSE Maxime. All rights reserved.
//

import UIKit
import CoreData

class EditItemViewController: UIViewController {
    
    
    var newItem: TodoItem?
    var catList = [Category]()
    var selectedCategory = ""
    let context = DataManager.SharedDataManager.context


    @IBOutlet weak var tf: UITextField!
    @IBOutlet weak var categoryPicker: UIPickerView!
    @IBOutlet weak var tv_description: UITextView!
    @IBOutlet weak var datePicker: UIDatePicker!
    @IBOutlet weak var icone: UIImageView!
    
    override func viewWillAppear(_ animated: Bool) {
        loadItems()
    }
    func loadItems() {
        let fetchRequest: NSFetchRequest<Category> = NSFetchRequest<Category>(entityName: "catName")
        do {
            let fetchedResults = try self.context.fetch(fetchRequest)
            let results = fetchedResults as [NSManagedObject]
            
            for item in results {
                print("coucou")
                catList.append(item as! Category)
            }
        } catch let error as NSError {
            print("Could not fetch : \(error)")
        }
        
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        categoryPicker.dataSource = self
        categoryPicker.delegate = self
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(done))
        tf.text = newItem?.title
        tv_description.text = newItem?.summary
        datePicker.date = newItem?.date ?? datePicker.date
        if((newItem?.category?.isEmpty)!){
            newItem?.category = "none"
        }
        let index = catList.index(where: {$0.catName == newItem?.category}) ?? 0
        categoryPicker.selectRow(index, inComponent: 0, animated: true)
    }
    
    @objc func done() {
        let controller = navigationController?.viewControllers[0] as! ViewController
        newItem?.title = tf.text!
        newItem?.summary = tv_description.text
        newItem?.date = datePicker.date
        newItem?.category = selectedCategory
        let position = controller.isFiltered ? controller.filteredItems.index(where: {$0 === newItem})! : controller.items.index(where: {$0 === newItem})!
        controller.tableView.reloadRows(at: [IndexPath(row: position, section: 0)], with: .automatic)
        controller.searchBarTextDidEndEditing(controller.searchBar)
        navigationController?.popViewController(animated: true)
    }
}

extension EditItemViewController : UIPickerViewDelegate, UIPickerViewDataSource {
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        self.selectedCategory = catList[row].catName!
        print(selectedCategory)

        return catList[row].catName
    }
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return catList.count
    }
    
    
}
