//
//  EditItemViewController.swift
//  DoItDBMobile
//
//  Created by MALOSSE Maxime on 22/02/2019.
//  Copyright © 2019 MALOSSE Maxime. All rights reserved.
//

import UIKit

class EditItemViewController: UIViewController {
    
    
    var newItem: TodoItem?
    var catList = ["Cat1", "Cat2", "Cat3", "Cat4"]
    var selectedCategory = ""
    
    @IBOutlet weak var tf: UITextField!
    @IBOutlet weak var categoryPicker: UIPickerView!
    @IBOutlet weak var tv_description: UITextView!
    @IBOutlet weak var datePicker: UIDatePicker!
    @IBOutlet weak var icone: UIImageView!
    
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
        let index = catList.index(where: {$0 == newItem?.category}) ?? 1
        categoryPicker.selectRow(index, inComponent: 0, animated: true)
        if newItem?.image != nil {
            icone.image = UIImage(data: ((newItem?.image)!))
        } else {
            icone.image = UIImage(named: "icon.png")
        }
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
        let position = controller.isFiltered ? controller.filteredItems.index(where: {$0 === newItem})! : controller.items.index(where: {$0 === newItem})!
        controller.tableView.reloadRows(at: [IndexPath(row: position, section: 0)], with: .automatic)
        controller.searchBarTextDidEndEditing(controller.searchBar)
        navigationController?.popViewController(animated: true)
    }
}

extension EditItemViewController : UIPickerViewDelegate, UIPickerViewDataSource {
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        self.selectedCategory = catList[row]
        print(selectedCategory)
        
        return catList[row]
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
