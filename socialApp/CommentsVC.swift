//
//  CommentsVC.swift
//  socialApp
//
//  Created by Oleg Pavlichenkov on 30/11/2016.
//  Copyright © 2016 Oleg Pavlichenkov. All rights reserved.
//

import UIKit

class CommentsVC: UIViewController, UITextFieldDelegate {

    @IBOutlet weak var commentTextField: UITextField!
    
    @IBOutlet weak var scrollView: UIScrollView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        commentTextField.delegate = self
        scrollView.isScrollEnabled = false
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: .UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: .UIKeyboardWillHide, object: nil)
    
    }
        
    func keyboardWillShow(notification: Notification){
        if commentTextField.isFirstResponder {
            if let userInfo = notification.userInfo {
                let keyboardFrame = (userInfo[UIKeyboardFrameEndUserInfoKey] as AnyObject).cgRectValue
                commentViewScrollUp(keyboardFrame: keyboardFrame!)
            }
        }
    }
    
    func commentViewScrollUp(keyboardFrame: CGRect){
        scrollView.setContentOffset(CGPoint(x: 0, y: (keyboardFrame.size.height)), animated: false)
    }
    
    func keyboardWillHide(){
        commentViewScrollDown()
    }
    
    func commentViewScrollDown(){
        scrollView.setContentOffset(CGPoint(x: 0, y: 0), animated: true)
    }
    
    @IBAction func scrollVIewTapped(_ sender: Any) {
        if commentTextField.isFirstResponder {
            commentTextField.endEditing(true)
        }
        
    }
    
    func textFieldDidEndEditing(_ textField: UITextField, reason: UITextFieldDidEndEditingReason) {
        textField.resignFirstResponder()
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField.isEqual(commentTextField) {
                sendComment()
        }
        return true
    }
   
    @IBAction func onSendButtonTapped(_ sender: Any) {
        sendComment()
    }

    func sendComment() {
        if let commentText = commentTextField.text, commentText != "" {
            print("==== sendComment: \(commentText)\n")
            commentTextField.text = ""
            
            //commentTextField.resignFirstResponder() 
            //update tableView
        }

    }
    
}
