//
//  LogInViewController.swift
//  ScholarHighPrototype1
//
//  Created by 広瀬陽一 on 2018/10/27.
//  Copyright © 2018 FRESHNESS. All rights reserved.
//

import UIKit
import Firebase

class LogInViewController: UIViewController {

    @IBOutlet weak var userNameTextField: UITextField!
    @IBOutlet weak var fieldBackingView: UIView!
    @IBOutlet weak var nameMissingAlert: UILabel!
    @IBOutlet weak var bottomConstraint: NSLayoutConstraint!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(keyboardWillShow(_:)),
                                               name: UIResponder.keyboardWillShowNotification,
                                               object: nil
        )
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(keyboardWillHide(_:)),
                                               name: UIResponder.keyboardWillHideNotification,
                                               object: nil
        )
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        userNameTextField.becomeFirstResponder()
    }
    
    @IBAction func onStartButtonTapped(_ sender: UIButton) {
       signIn()
    }
    
    
    func signIn() {
        guard let name = userNameTextField.text, !name.isEmpty  else {
            // show Name-Missing Alert
            nameMissingAlert.text = "ユーザー名を入力してください"
            return
        }
        
        nameMissingAlert.text = ""
        AppDefs.displayName = name
        
        Auth.auth().signInAnonymously() {(authResult, error) in
            let user = authResult?.user
            let isAnonymous = user?.isAnonymous
            
            if isAnonymous == true {
                self.nameMissingAlert.text = "true"
            } else {
                self.nameMissingAlert.text = "false"
            }
        }
        
    }
    
    @objc private func keyboardWillShow(_ notification: Notification) {
        guard let userInfo = notification.userInfo else {
            return
        }
        guard let keyboardHeight = (userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue.height else {
            return
        }
        guard let keyboardAnimationDuration = (userInfo[UIResponder.keyboardAnimationDurationUserInfoKey] as? NSNumber)?.doubleValue else {
            return
        }
        guard let keyboardAnimationCurve = (userInfo[UIResponder.keyboardAnimationCurveUserInfoKey] as? NSNumber)?.uintValue else {
            return
        }
        
        let options = UIView.AnimationOptions(rawValue: keyboardAnimationCurve)
        bottomConstraint.constant = keyboardHeight
        UIView.animate(withDuration: keyboardAnimationDuration, delay: 0, options: options, animations: {
           self.view.layoutIfNeeded()
        }, completion: nil)
    }
        
    
    @objc private func keyboardWillHide(_ notification: Notification) {
        guard let userInfo = notification.userInfo else {
            return
        }
        guard let keyboardAnimationDuration = (userInfo[UIResponder.keyboardAnimationDurationUserInfoKey] as? NSNumber)?.doubleValue else {
            return
        }
        guard let keyboardAnimationCurve = (userInfo[UIResponder.keyboardAnimationCurveUserInfoKey] as? NSNumber)?.uintValue else {
            return
        }
        
        let options = UIView.AnimationOptions(rawValue: keyboardAnimationCurve << 16)
        bottomConstraint.constant = 20
        
        UIView.animate(withDuration: keyboardAnimationDuration, delay: 0, options: options, animations: {
            self.fieldBackingView.layoutIfNeeded()
        }, completion: nil)
        
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
