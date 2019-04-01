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
    private var catList = [Category]()
    private var selectedCategory = ""
    private let context = DataManager.SharedDataManager.context
    private var categoryPicker = UIPickerView()
    private var datePicker = UIDatePicker()
    private let dateFormatter = DateFormatter()

    @IBOutlet weak var tf: UITextField!
    @IBOutlet weak var categoryTextField: UITextField!
    @IBOutlet weak var tv_description: UITextView!
    @IBOutlet weak var icone: UIImageView!
    @IBOutlet weak var dateTextField: UITextField!
    
    override func viewWillAppear(_ animated: Bool) {
        loadItems()
        
    }
    
    func loadItems() {
        let fetchRequest: NSFetchRequest<Category> = NSFetchRequest<Category>(entityName: "Category")
        do {
            let fetchedResults = try self.context.fetch(fetchRequest)
            let results = fetchedResults as [NSManagedObject]
            
            for item in results {
                catList.append(item as! Category)
            }
        } catch let error as NSError {
            print("Could not fetch : \(error)")
        }
        
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.dateFormatter.dateStyle = .medium
        self.dateFormatter.timeStyle = .none
        self.dateFormatter.locale = Locale(identifier: "fr_FR")
        
        categoryPicker.dataSource = self
        categoryPicker.delegate = self
        
        let gestureRecognizer = UITapGestureRecognizer()
        icone.isUserInteractionEnabled = true
        gestureRecognizer.addTarget(self, action: #selector(self.selectImage))
        icone.addGestureRecognizer(gestureRecognizer)
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(done))
        tf.text = newItem?.title
        tv_description.text = newItem?.summary
        datePicker.date = newItem?.date ?? datePicker.date
        datePicker.datePickerMode = .date
        datePicker.locale = Locale(identifier: "fr_FR")
        
        
        if newItem?.category?.isEmpty ?? false {
            newItem?.category = "none"
        }
        
        categoryTextField.text = newItem?.category
        
        if newItem?.date != nil {
            dateTextField.text = self.dateFormatter.string(from: newItem!.date!)
        }
        
        if newItem?.image != nil {
            icone.image = UIImage(data: ((newItem?.image)!))
        } else {
            icone.image = UIImage(named: "imagePickerIcone.png")
        }
        categoryTextField.inputView = categoryPicker
        dateTextField.inputView = datePicker
        datePicker.addTarget(self, action: #selector(chooseDate), for: .valueChanged)
        dateTextField.addTarget(self, action: #selector(chooseDate), for: .editingDidBegin)
    }
    
    @objc
    func chooseDate() {
        let date: Date = datePicker.date
        self.dateTextField.text =  "\(self.dateFormatter.string(from: date))"
        print("here")
    }
    
    @objc func selectImage () {
        let picker = UIImagePickerController()
        picker.delegate = self
        picker.sourceType = .photoLibrary
        picker.allowsEditing = true
        present(picker, animated: true, completion: nil)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        icone.image = info[.editedImage] as? UIImage
        self.dismiss(animated: true, completion: nil)
    }
    
    @objc func done() {
        let controller = navigationController?.viewControllers[0] as! ViewController
        newItem?.title = tf.text!
        newItem?.summary = tv_description.text
        newItem?.date = datePicker.date
        newItem?.category = categoryTextField.text
        let data = icone.image?.jpegData(compressionQuality: 0.5)
        newItem?.setValue(data, forKey: "image")
//      let position = controller.isFiltered ? controller.filteredItems.index(where: {$0 === newItem})! : controller.items.index(where: {$0 === newItem})!
        controller.tableView.reloadData()
        controller.searchBarTextDidEndEditing(controller.searchBar)
        navigationController?.popViewController(animated: true)
    }
}

extension EditItemViewController : UIPickerViewDelegate, UIPickerViewDataSource {

    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        selectedCategory = catList[row].catName!
    }

    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        self.selectedCategory = catList[row].catName!
        self.categoryTextField.text = selectedCategory
        return catList[row].catName
    }
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return catList.count
    }
    
}


extension EditItemViewController : UINavigationControllerDelegate, UIImagePickerControllerDelegate {
    
}
