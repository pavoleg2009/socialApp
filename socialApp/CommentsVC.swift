//
//  CommentsVC.swift
//  socialApp
//
//  Created by Oleg Pavlichenkov on 30/11/2016.
//  Copyright © 2016 Oleg Pavlichenkov. All rights reserved.
//

import UIKit
import Firebase


class CommentsVC: UIViewController, UITextFieldDelegate, UITableViewDelegate, UITableViewDataSource {
    
    var post: Post!
    var users = [User]()
    var usersDict: Dictionary<String, User> = [:]
    var commentsHandle: FIRDatabaseHandle!
    var commentsOrderedByChild: String = "dateOfCreate"
    var commentsArray = [Comment]()
    var cellId = "commentCellId"
    
    @IBOutlet weak var postCaptionLabel: UILabel!
    @IBOutlet weak var commentTextField: UITextField!
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var tableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        commentTextField.delegate = self
        scrollView.isScrollEnabled = false
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: .UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: .UIKeyboardWillHide, object: nil)
    
    }
    
    override func viewWillAppear(_ animated: Bool) {
        if post != nil {
            setTableView()
            postCaptionLabel.text = post.caption
            setCommentsObserver(){
                DispatchQueue.main.async {
                    self.tableView.reloadData()
                }
            }
        }
    }
////////////////////////////////
//  Setting tableView
////////////////////////////////
    func setTableView(){
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(CommentCell.self, forCellReuseIdentifier: cellId)
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
        
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return commentsArray.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: cellId, for: indexPath) as! CommentCell
        
        cell.configureCell(comment: commentsArray[indexPath.row])
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 80
    }

    
////////////////////////////////
// commentTextField: alignind to keyboard
////////////////////////////////
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
    
////////////////////////////////
//  Creating new comment
////////////////////////////////
    @IBAction func onSendButtonTapped(_ sender: Any) {
        sendComment()
    }

    func sendComment() {
        if let commentText = commentTextField.text, commentText != "" {
            saveCommentToDB(commentText)
            
            commentTextField.text = ""
            
            //commentTextField.resignFirstResponder() 
            tableView.reloadData()
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
    
////////////////////////////////
//  Reading comments and users
////////////////////////////////
    
    func setCommentsObserver(completion: @escaping ()-> Void) {
        
        commentsHandle = DataService.ds.REF_POSTS.child("\(post.postKey)/comments").queryOrdered(byChild: commentsOrderedByChild).observe(.value, with: { (snapshot) in
            if let snapshots = snapshot.children.allObjects as? [FIRDataSnapshot] {
                
                self.commentsArray = snapshots.map(self.mapSnapshotToComment)
                self.setUserSingleObserver(){
                    self.commentsArray = self.commentsArray.map(self.addUserDataToComment)
                    completion()
                }
                
                
            } else {
                completion()
            }
            
        }, withCancel: { (error) in
            print("===[CommentsVC] DB Error (setupCommentsObserver) : \(error)\n")
            completion()
        })
    }
    
    
    func mapSnapshotToComment(snap: FIRDataSnapshot) -> Comment {
        if let commentDict = snap.value as? [String : Any] {
            return Comment(commentKey: snap.key, commentData: commentDict) // not shure if 3 strings above required
        } else {
            return Comment()
        }
    }
    
    func setUserSingleObserver(completion: @escaping ()-> Void){
        DataService.ds.REF_USERS.observeSingleEvent(of: .value, with: { (snapshot) in
            
            if let snapshots = snapshot.children.allObjects as? [FIRDataSnapshot] {
                self.users = snapshots.map(self.mapSnapshotToUser)
                for user in self.users {
                    self.usersDict[user.userKey!] = user
                }
                completion()
            } else {
                completion()
            }
            
        }, withCancel: { (error) in
            print("===[FeedVC] DB Error (setupPostsObserver) !! : \(error)\n")
            completion()
        })
    }

    func mapSnapshotToUser(snap: FIRDataSnapshot) -> User {
        if let userDict = snap.value as? [String : Any] {
            return User(userKey: snap.key, userData: userDict)
        } else {
            return User()
        }
    }
    
    func addUserDataToComment(comment: Comment) -> Comment {
        if let userName = usersDict[comment.authorKey]?.userName {
            comment.authorName = userName
        }
        
        if let avatarUrl = usersDict[comment.authorKey]?.avatarUrl {
            comment.authorAvatarUrl = avatarUrl
        }
        
        return comment
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        removeCommentsObserver()
    }
    
    func removeCommentsObserver(){
        if let _ = commentsHandle {
            DataService.ds.REF_POSTS.removeObserver(withHandle: commentsHandle)
        }
        
    }
////////////////////////////////
    
    @IBAction func backBtnTapped(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
}
