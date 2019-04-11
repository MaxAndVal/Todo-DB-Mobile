//
//  EditItemViewController.swift
//  DoItDBMobile
//
//  Created by MALOSSE Maxime on 22/02/2019.
//  Copyright © 2019 MALOSSE Maxime. All rights reserved.
//

import UIKit
import CoreData

class EditItemViewController: UIViewController, UINavigationControllerDelegate {
    
    //MARK : - Vars
    var newItem: TodoItem?
    private var catList = [Category]()
    private var selectedCategory = ""
    private let context = DataManager.SharedDataManager.context
    private var categoryPicker = UIPickerView()
    private var datePicker = UIDatePicker()
    private let dateFormatter = DateFormatter()
    private let imagePicker = UIImagePickerController()
    var delegate: EditItemControllerDelegate!

    //MARK : - IBOutlets
    @IBOutlet weak var tf: UITextField!
    @IBOutlet weak var categoryTextField: UITextField!
    @IBOutlet weak var tv_description: UITextView!
    @IBOutlet weak var icone: UIImageView!
    @IBOutlet weak var dateTextField: UITextField!
    
    //MARK : - ViewWillAppear
    override func viewWillAppear(_ animated: Bool) {
        loadItems()
    }
    
    //MARK : - ViewDidLoad
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.dateFormatter.dateStyle = .medium
        self.dateFormatter.timeStyle = .none
        self.dateFormatter.locale = Locale(identifier: "fr_FR")
        
        categoryPicker.dataSource = self
        categoryPicker.delegate = self
        
        initImageTouchListener()
        fillFields()
        datePicker.datePickerMode = .date
        datePicker.locale = Locale(identifier: "fr_FR")
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(done))
        bindKeyBoards()
    }
    
    // Load Items
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
    
    //MARK : - fill Fields
    func fillFields() {
        if let realNewItem: TodoItem = newItem {
            if let imageData: Data = realNewItem.image {
                icone.image = UIImage(data: (imageData))
            } else {
                icone.image = UIImage(named: "imagePickerIcone.png")
            }
            if realNewItem.category?.isEmpty ?? false {
                newItem?.category = "none"
            }
            categoryTextField.text = realNewItem.category
            if let realDate: String = realNewItem.date {
                dateTextField.text = self.dateFormatter.string(for: realDate)//self.dateFormatter.string(from: realDate)
                datePicker.date = self.dateFormatter.date(from: realDate) ?? Date()
            } else {
                datePicker.date = Date()
            }
            tv_description.text = realNewItem.summary
            tf.text = realNewItem.title
        }
    }
    
    //MARK : - Bind KeyBoards
    func bindKeyBoards() {
        categoryTextField.inputView = categoryPicker
        dateTextField.inputView = datePicker
        datePicker.addTarget(self, action: #selector(chooseDate), for: .valueChanged)
        dateTextField.addTarget(self, action: #selector(chooseDate), for: .editingDidBegin)
    }
    
    //MARK : - Init Image Listener
    func initImageTouchListener() {
        let gestureRecognizer = UITapGestureRecognizer()
        icone.isUserInteractionEnabled = true
        gestureRecognizer.addTarget(self, action: #selector(self.selectImage))
        icone.addGestureRecognizer(gestureRecognizer)
        imagePicker.delegate = self
        imagePicker.sourceType = .photoLibrary
        imagePicker.allowsEditing = true
    }
    
    //MARK : - Date Picker
    @objc
    func chooseDate() {
        let date: Date = datePicker.date
        self.dateTextField.text =  "\(self.dateFormatter.string(from: date))"
        print("here")
    }
    
    // Image Picker
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        icone.image = info[.editedImage] as? UIImage
        self.dismiss(animated: true, completion: nil)
    }
    
    @objc
    func selectImage () {
        present(imagePicker, animated: true, completion: nil)
    }
    
    //MARK : - Done btn
    @objc func done() {
        let controller = navigationController?.viewControllers[0] as! ViewController
        newItem?.title = tf.text!
        newItem?.summary = tv_description.text
        newItem?.date = datePicker.date.description
        newItem?.category = categoryTextField.text
        let data = icone.image?.jpegData(compressionQuality: 0.5)
        let realData = data?.base64EncodedData()
        newItem?.setValue(realData, forKey: "image")
        
        delegate.didFinishEditItem(controller: controller, item: newItem!)
    }
}

//MARK : - Pickers Extensions
extension EditItemViewController : UIPickerViewDelegate, UIPickerViewDataSource, UIImagePickerControllerDelegate {

    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        self.selectedCategory = catList[row].catName!
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

protocol EditItemControllerDelegate : class {
    func didFinishEditItem(controller: ViewController, item: TodoItem)
}
