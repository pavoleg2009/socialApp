//
//  CommentsVC.swift
//  socialApp
//
//  Created by Oleg Pavlichenkov on 30/11/2016.
//  Copyright © 2016 Oleg Pavlichenkov. All rights reserved.
//

import UIKit
import Firebase

class CommentsVC: UIViewController, UITextFieldDelegate {
    
    var post: Post!
    
    @IBOutlet weak var postCaptionLabel: UILabel!
    @IBOutlet weak var commentTextField: UITextField!
    @IBOutlet weak var scrollView: UIScrollView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        commentTextField.delegate = self
        scrollView.isScrollEnabled = false
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: .UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: .UIKeyboardWillHide, object: nil)
    
    }
    
    override func viewWillAppear(_ animated: Bool) {
        if post != nil {
            postCaptionLabel.text = post.caption
        }
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
            saveCommentToDB(commentText)
            
            commentTextField.text = ""
            
            //commentTextField.resignFirstResponder() 
            //update tableView
        }

    }
    
    func saveCommentToDB(_ commentText: String?){
        
        if commentText != nil {
            prepareCommentData(commentText: commentText!){ (newCommentRef, newCommentData) in
                self.createCommentInDb(commentRef: newCommentRef, commentData: newCommentData) {
                    //update tableView
                }

            }
        }
    }
    
    func prepareCommentData(commentText: String, completion: @escaping (_ firebaseCommentRef: FIRDatabaseReference, _ commentData: [String : Any])->Void){
        let newCommentData: [String: Any] = [
            "caption" : commentText,
            "likes" : 0,
            "authorKey" : CurrentUser.cu.currentDBUser.userKey!,
            "dateOfCreate": [".sv": "timestamp"],
            "dateOfUpdate": [".sv": "timestamp"]
        ]
        
        let newCommentRef = DataService.ds.REF_POSTS.child("\(post.postKey)/comments").childByAutoId()
        
        completion(newCommentRef, newCommentData)
        
    }
    
    func createCommentInDb(commentRef: FIRDatabaseReference, commentData: [String : Any], completion: @escaping()->Void){
        commentRef.setValue(commentData) { (err, ref) in
            if err != nil {
                print("===[CommentsVC].createCommentinDb : ERROR creating comment in Firebase DB\(err.debugDescription)\n")
                return
            } else {
                print("==[CommentsVC].createCommentinDb : Comment created in : \(ref.key)\n")
            }
        }
    }
    
    @IBAction func backBtnTapped(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
}
