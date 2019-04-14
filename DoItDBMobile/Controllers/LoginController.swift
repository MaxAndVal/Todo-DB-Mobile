//
//  LoginController.swift
//  DoItDBMobile
//
//  Created by MALOSSE Maxime on 09/04/2019.
//  Copyright © 2019 MALOSSE Maxime. All rights reserved.
//

import UIKit
import Firebase

class LoginController: UIViewController {

    @IBOutlet weak var segmentedController: UISegmentedControl!
    @IBOutlet weak var nameTF: UITextField!
    @IBOutlet weak var emailTF: UITextField!
    @IBOutlet weak var passwordTF: UITextField!
    @IBOutlet weak var loginRegisterBtn: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        loginRegisterBtn.titleLabel?.text = "Register"
        segmentedController.selectedSegmentIndex = 1
        segmentedController.addTarget(self, action: #selector(handleLoginRegisterChoice), for: .valueChanged)
        loginRegisterBtn.addTarget(self, action: #selector(handleLoginOrRegister), for: .touchUpInside)
        
        isAlreadyLogged()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        clearTF()
    }
    
    func clearTF() {
        nameTF.text = ""
        emailTF.text = ""
        passwordTF.text = ""
    }

    func isAlreadyLogged() {
        if Auth.auth().currentUser != nil {
            print("already logged !")
            performSegue(withIdentifier: "LoggedSegue", sender: nil)
        }
    }
    
    @objc
    func handleLoginRegisterChoice() {
        if segmentedController.selectedSegmentIndex == 0 {
            nameTF.isHidden = true
            loginRegisterBtn.titleLabel?.text = "Login"
        } else {
            nameTF.isHidden = false
            loginRegisterBtn.titleLabel?.text = "Register"
        }
        
    }
    
    @objc
    func handleLoginOrRegister() {
        if segmentedController.selectedSegmentIndex == 0 {
            handleLoging()
        } else {
            handleRegister()
        }
    }
    
    @objc
    func handleLoging() {
        guard let email = emailTF.text, let password = passwordTF.text else {
            print("Form not complete")
            return
        }
        Auth.auth().signIn(withEmail: email, password: password) { (result, error) in
            if error != nil {
                print(error)
                return
            }
            print("user logged succesfully")
            self.performSegue(withIdentifier: "LoggedSegue", sender: nil)
        }
        
        
    }
    
    @objc
    func handleRegister() {
        guard let name = nameTF.text, let email = emailTF.text, let password = passwordTF.text else {
            print("Form not complete")
            return
        }
        Auth.auth().createUser(withEmail: email, password: password) { (authResult : AuthDataResult?, error :Error?) in
            
            if error != nil {
                print(error)
                return
            }
            print("user logged succesfully")
            guard let user = authResult?.user else {
                return
            }

            //succesfully authenticated user
            let values = ["name": name, "email": email, "TodoItems": "", "Categories": ""]
            let ref = Database.database().reference(fromURL: "https://todoapp-e390f.firebaseio.com/").child("users")
            ref.child(user.uid).child("userData").updateChildValues(values, withCompletionBlock: { (error, databaseRef) in
                if error != nil {
                    print(error)
                    return
                }
                print("user saved in firebse db")
                self.performSegue(withIdentifier: "LoggedSegue", sender: nil)
            })

            
            
            
        }
        
    }
}
