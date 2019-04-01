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
    private var categoryPicker = UIPickerView()
    @IBOutlet weak var categoryTextField: UITextField!
    @IBOutlet weak var tv_description: UITextView!
    private var datePicker = UIDatePicker()
    @IBOutlet weak var icone: UIImageView!
    @IBOutlet weak var dateTextField: UITextField!
    
    override func viewWillAppear(_ animated: Bool) {
        loadItems()
        categoryPicker.selectRow(1, inComponent: 0, animated: true)
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
        
        
        if((newItem?.category?.isEmpty ?? false)){
            newItem?.category = "none"
        }
        
        if newItem?.image != nil {
            icone.image = UIImage(data: ((newItem?.image)!))
        } else {
            icone.image = UIImage(named: "icon.png")
        }
        categoryTextField.inputView = categoryPicker
        dateTextField.inputView = datePicker
        datePicker.addTarget(self, action: #selector(chooseDate), for: .valueChanged)
        dateTextField.addTarget(self, action: #selector(chooseDate), for: .editingDidBegin)
    }
    
    @objc
    func chooseDate() {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .none
        let date: Date = datePicker.date
        dateFormatter.locale = Locale(identifier: "fr_FR")
        
        self.dateTextField.text =  "\(dateFormatter.string(from: date))"
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
        newItem?.category = selectedCategory
        let data = icone.image?.jpegData(compressionQuality: 0.5)
        newItem?.setValue(data, forKey: "image")
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
