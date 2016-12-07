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
    
    private var commentsHandle: FIRDatabaseHandle!
    private var commentsOrderedByChild: String = "dateOfCreate"
    private var commentsArray = [Comment]()
    private var cellId = "commentCellId"
    private var _commentTextFieldFocusedFor: OpenedFor = .none
    
    private var editingComment: Comment?
    
    var commentTextFieldFocusedFor: OpenedFor {
        get {
            return _commentTextFieldFocusedFor
        } set {
            _commentTextFieldFocusedFor = newValue
            switch _commentTextFieldFocusedFor {
            case .create:
                postCaptionLabel.text = ">New Comment<"
            case .edit:
                postCaptionLabel.text = ">Edit Comment<"
            default:
                postCaptionLabel.text = post.caption
            }
        }
    }
    
    @IBOutlet weak var postCaptionLabel: UILabel!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var commentTextField: UITextField!
    @IBOutlet weak var returnButton: UIButton!
    
////////////////////////////////
// Initiatin VC
////////////////////////////////
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        commentTextField.delegate = self
        //handle keyboard shwowing/hiding
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillChangeRect), name: .UIKeyboardWillChangeFrame, object: nil)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        setReturnButton(setFor: commentTextFieldFocusedFor)
        commentTextField.clearButtonMode = .whileEditing
        if post != nil {
            setTableView()
            postCaptionLabel.text = post.caption
            setCommentsObserver(){
                DispatchQueue.main.async {
                    self.tableView.reloadData()
                    self.tableViewScrollToBottom()
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
        tableView.allowsSelection = false
        tableView.register(CommentCell.self, forCellReuseIdentifier: cellId)
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 80
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return commentsArray.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: cellId, for: indexPath) as! CommentCell
        cell.configureCell(comment: commentsArray[indexPath.row])
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // to allow swipe and show Edit and Delete button for author of comment
        return !(commentTextField.isEditing) && (commentsArray[indexPath.row].currentUserIsAuthor)
        //        return (tableView.cellForRow(at: indexPath) as! CommentCell).comment.currentUserIsAuthor
    }
    
    func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        let editAction = UITableViewRowAction(style: .normal, title: " Edit    ") { (tableViewRowAction, indexPath) in
            self.commentStartEditingAt(indexPath)
        }
        editAction.backgroundColor = UIColor.blue

        let deleteAction = UITableViewRowAction(style: .destructive, title: "Delete") { (tableViewRowAction, indexPath) in
            self.deleteComment(indexPath)
        }
        
        return [deleteAction, editAction]
    }
    
    func tableView(_ tableView: UITableView, didEndEditingRowAt indexPath: IndexPath?) {
        finishCommentEditing()
        editingComment = nil
    }
    
    func tableViewScrollToBottom() {
        if tableView.numberOfRows(inSection: 0) > 1 {
            let indexPath = IndexPath(row: self.tableView.numberOfRows(inSection: 0)-1, section: 0)
            self.tableView.scrollToRow(at: indexPath , at: UITableViewScrollPosition.bottom, animated: false)
        }
    }
    
////////////////////////////////
    // This constraint ties an element at zero points from the bottom layout guide
    
    @IBOutlet var keyboardHeightLayoutConstraint: NSLayoutConstraint?

    
    func keyboardWillChangeRect(notification: Notification) {
        if let userInfo = notification.userInfo {
            let endFrame = (userInfo[UIKeyboardFrameEndUserInfoKey] as AnyObject).cgRectValue
            let duration: TimeInterval = (userInfo[UIKeyboardAnimationDurationUserInfoKey] as? NSNumber)?.doubleValue ?? 0
            let animationCurveRawNSN = userInfo[UIKeyboardAnimationCurveUserInfoKey] as? NSNumber
            let animationCurveRaw = animationCurveRawNSN?.uintValue ?? UIViewAnimationOptions.curveEaseInOut.rawValue
            let animationCurve: UIViewAnimationOptions = UIViewAnimationOptions(rawValue: animationCurveRaw)

            
            if (endFrame?.origin.y)! >= UIScreen.main.bounds.size.height {
                self.keyboardHeightLayoutConstraint?.constant = 0.0
            } else {
                self.keyboardHeightLayoutConstraint?.constant = endFrame?.size.height ?? 0.0
            }
            
            UIView.animate(withDuration: duration,
                           delay: TimeInterval(0),
                           options: animationCurve,
                           animations: { self.view.layoutIfNeeded() },
                           completion: nil)

        
            self.tableViewScrollToBottom()
        
        }
    }

////////////////////////////////
// textField handling
////////////////////////////////
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        if commentTextFieldFocusedFor == .none {
            commentTextFieldFocusedFor = .create
        }
    }

    @IBAction func commentTextFieldEditingChanged(_ sender: UITextField) {
        // change button after some small delay
        if commentTextField.text == "" || (commentTextFieldFocusedFor == .edit && commentTextField.text == editingComment?.caption) {
            setReturnButton(setFor: .none)
        }
    }

    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        if textField.isEqual(commentTextField) {
            
            if (textField.text == "" && string != "") || (commentTextFieldFocusedFor == .edit && textField.text == editingComment?.caption) {
                setReturnButton(setFor: commentTextFieldFocusedFor)
            }
        }
        return true
    }
    
    @IBAction func commetnTextFieldEditingDidEnd(_ sender: UITextField) {
        if commentTextField.text == "" {
            finishCommentEditing()
        }
    }
    
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField.isEqual(commentTextField) {
                returnButton.sendActions(for: UIControlEvents.touchUpInside)
        }
        return true
    }
    
///////////////////////////
//  setting button responsive to captionText state and create/edit option
///////////////////////////
    
    func setReturnButton(setFor: OpenedFor){
        
        switch setFor {
        case .create:
            setReturnButtonForCreate()
        case .edit:
            setReturnButtonForUpdate()
        default:
            setReturnButtonForNone()
        }
    }
    
    func setReturnButtonForCreate(){
        returnButton.setTitle("+", for: UIControlState.normal)
        returnButton.removeTarget(nil, action: nil, for: .touchUpInside)
        returnButton.addTarget(self, action: #selector(onReturnButtonTappedForCreate(_:)), for: .touchUpInside)
        returnButton.backgroundColor = UIColor.blue
        
    }
    func setReturnButtonForUpdate(){
        returnButton.setTitle("√", for: UIControlState.normal)
        returnButton.removeTarget(nil, action: nil, for: .touchUpInside)
        returnButton.addTarget(self, action: #selector(onReturnButtonTappedForUpdate(_:)), for: .touchUpInside)
        returnButton.backgroundColor = UIColor.orange
    }
    
    func setReturnButtonForNone(){
        returnButton.setTitle("…", for: UIControlState.normal)
        returnButton.removeTarget(nil, action: nil, for: .touchUpInside)
        returnButton.backgroundColor = nil
    }
    
    
////////////////////////////////
//  Creating new comment
////////////////////////////////
    func onReturnButtonTappedForCreate(_ sender: Any) {
        createComment()
    }

    func createComment() {
        
        if let commentText = commentTextField.text, commentText != "" {
            
            prepareCommentDataForCreate(commentText: commentText){ (newCommentRef, newCommentData) in
                self.createCommentInDb(commentRef: newCommentRef, commentData: newCommentData) {
                    
                }
            }
            finishCommentEditing()
        }
    }

    
    func prepareCommentDataForCreate(commentText: String, completion: @escaping (_ firebaseCommentRef: FIRDatabaseReference, _ commentData: [String : Any])->Void){
        
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
//                print("==[CommentsVC].createCommentinDb : Comment created in : \(ref.key)\n")
            }
        }
    }
    
    func finishCommentEditing(){
        
        commentTextFieldFocusedFor = .none
        setReturnButton(setFor: .none)
        commentTextField.text = ""
        postCaptionLabel.text = post.caption
        // nay be this line is enough
        commentTextField.endEditing(true)
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
            return Comment(postKey: post.postKey, commentKey: snap.key, commentData: commentDict) // not shure if 3 strings above required
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
            print("===[CommentVC] DB Error (setUserSingleObserver) !! : \(error)\n")
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
        if let authorKey = comment.authorKey, let userName = usersDict[authorKey]?.userName {
            comment.authorName = userName
        }
        
        if let authorKey = comment.authorKey, let avatarUrl = usersDict[authorKey]?.avatarUrl {
            comment.authorAvatarUrl = avatarUrl
        }
        
        return comment
    }
    
////////////////////////////////
//  Update Comment - only text and dateOfUpdate
////////////////////////////////
    
    func commentStartEditingAt(_ indexPath: IndexPath){
        
        if let comment = (tableView.cellForRow(at: indexPath) as! CommentCell).comment {
            // set commentText to commentEdit
            editingComment = comment
            commentTextField.text = comment.caption
            commentTextFieldFocusedFor = .edit
            setReturnButton(setFor: .none)
            commentTextField.becomeFirstResponder()
        }
    }

    
    func onReturnButtonTappedForUpdate(_ sender: Any){
        updateComment()
    }
    
    func updateComment(){
    
        if let newCommentCaptoion = commentTextField.text, let comment = editingComment, newCommentCaptoion != "" && tableView.isEditing && editingComment != nil {
            
            prepareCommentDataForUpdate(commentForUpdate: comment, commentCaption: newCommentCaptoion) { (updCommentRef, updCommentData) in
                self.updateCommentInDb(commentToUpdate: updCommentRef, updData: updCommentData)
            }
        editingComment = nil
        }
    }
    
    func prepareCommentDataForUpdate(commentForUpdate: Comment, commentCaption: String, completion: @escaping (_ firebaseCommentRef: FIRDatabaseReference, _ commentData: [String : Any])->Void){
        
        let updCommentData: [String: Any] = [
            "caption" : commentCaption,
            "dateOfUpdate": [".sv": "timestamp"]
        ]
        
        let updCommentRef = DataService.ds.REF_POSTS.child("\(post.postKey)/comments").child(commentForUpdate.commentKey!)
        
        completion(updCommentRef, updCommentData)
        
    }

    
    func updateCommentInDb(commentToUpdate: FIRDatabaseReference, updData: [String: Any]){
        
        commentToUpdate.updateChildValues(updData) { (error, ref) in
            if error != nil {
                print("===[CommentVC].updateCommentInDb() ERROR updating comment \n")
            }
        }
    }    
    
    @IBAction func viewTappedForCancelEditing(_ sender: Any) {
        cancelCommentEditig()
    }
    
    func cancelCommentEditig(){
        if commentTextField.isFirstResponder {
            commentTextField.endEditing(true)
        }
    }
    
////////////////////////////////
//  Delete Comment
////////////////////////////////
    
    func deleteComment(_ indexPath: IndexPath){
       
        let cellToDelete = tableView.cellForRow(at: indexPath) as! CommentCell
        
        if let commentKeyToDelete = cellToDelete.comment.commentKey, !commentTextField.isEditing {
            DataService.ds.REF_POSTS.child("\(post.postKey)/comments/\(commentKeyToDelete)").removeValue() { (error, ref) in
                if error != nil {
                    print("===[CommentVC].deleteComment() : ERROR : \(error.debugDescription) \n")
                }
                self.tableView.reloadData()
            }
        }
    }
    
////////////////////////////////
//  Deinitialize ViewController
////////////////////////////////
    
    override func viewWillDisappear(_ animated: Bool) {
        removeCommentsObserver()
    }
    
    func removeCommentsObserver(){
        if let _ = commentsHandle {
            DataService.ds.REF_POSTS.removeObserver(withHandle: commentsHandle)
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
////////////////////////////////
    
    @IBAction func backBtnTapped(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func testButtonClick(_ sender: Any) {
        
//        print(returnButton.allControlEvents.)
        
    }
    
}
