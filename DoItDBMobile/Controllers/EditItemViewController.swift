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
        self.dateFormatter.dateFormat = "dd MMM yyyy"
        self.dateFormatter.locale = Locale(identifier: "fr_FR")
        
        categoryPicker.dataSource = self
        categoryPicker.delegate = self
        
        setupTvDescription()
        initImageTouchListener()
        fillFields()
        datePicker.datePickerMode = .date
        datePicker.locale = Locale(identifier: "fr_FR")
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(done))
        navigationItem.rightBarButtonItem?.tintColor = #colorLiteral(red: 0, green: 0.5690457821, blue: 0.5746168494, alpha: 1)
        navigationItem.backBarButtonItem?.tintColor = #colorLiteral(red: 0, green: 0.5690457821, blue: 0.5746168494, alpha: 1)
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
            if let imageData: Data = try realNewItem.image {
                let realImage = Data(base64Encoded: imageData)!
                icone.image = UIImage(data: (realImage))
            } else {
                icone.image = UIImage(named: "imagePickerIcone.png")
            }
            if realNewItem.category?.isEmpty ?? false  || realNewItem.category == nil{
                newItem?.category = ""
            }
            categoryTextField.text = realNewItem.category
            
            if let realDate: String = realNewItem.date {
                dateTextField.text = realDate
                datePicker.date = dateFormatter.date(from: realDate) ?? Date()
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
    
    //MARK: - Setup tv_description
    func setupTvDescription() {
        tv_description.translatesAutoresizingMaskIntoConstraints = false
        tv_description.layer.cornerRadius = 4
        tv_description.layer.borderWidth = 1
        tv_description.layer.borderColor = #colorLiteral(red: 0.8980392157, green: 0.8980392157, blue: 0.8980392157, alpha: 1)
    }
    
    //MARK : - Date Picker
    @objc
    func chooseDate() {
        let date: Date = datePicker.date
        self.dateTextField.text =  "\(self.dateFormatter.string(from: date))"
    }
    
    // Image Picker
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        var selectedImageFromPicker : UIImage?
        
        if let editedImage = info[.editedImage] as? UIImage {
            selectedImageFromPicker = editedImage
        } else if let originalImage = info[.originalImage] as? UIImage {
            selectedImageFromPicker = originalImage
        }
        
        if let selectedImage = selectedImageFromPicker {
            icone.image = selectedImage
            newItem?.image = UIImage.pngData(selectedImage)()
        }
        
        self.dismiss(animated: true, completion: nil)
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        print("image selection cancelled")
        dismiss(animated: true, completion: nil)
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
        let dateText = dateTextField.text ?? ""
        if(!dateText.isEmpty){
            newItem?.date = dateFormatter.string(from: datePicker.date)
        }
        if(categoryTextField.text?.isEmpty ?? true){
            newItem?.category = nil
        }else{
            newItem?.category = categoryTextField.text
        }
        
        let data = icone.image?.pngData()
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
