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

    @IBOutlet weak var tf: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(done))
        // Do any additional setup after loading the view.
    }
    
    @objc func done() {
        let controller = navigationController?.viewControllers[0] as! ViewController
        newItem?.title = tf.text!
        let position = controller.items.index(where: {$0 === newItem})!
        controller.tableView.reloadRows(at: [IndexPath(row: position, section: 0)], with: .automatic)
        navigationController?.popViewController(animated: true)
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
