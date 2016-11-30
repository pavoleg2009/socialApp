//
//  FeedVC.swift
//  socialApp
//
//  Created by Oleg Pavlichenkov on 09/11/2016.
//  Copyright © 2016 Oleg Pavlichenkov. All rights reserved.
//

import UIKit
import Firebase
import SwiftKeychainWrapper

class FeedVC: UIViewController, UITableViewDelegate, UITableViewDataSource, UIImagePickerControllerDelegate, UINavigationControllerDelegate, MyCustomCellDelegator {
    
    var posts = [Post]()
    var users = [User]()
    var usersDict: Dictionary<String, User> = [:]
    var imagePicker: UIImagePickerController!
    var imageSelected = false
    
    private var authStateDidChangeListenerHandle: FIRAuthStateDidChangeListenerHandle!
    var postsHandle: UInt!
    var usersHandle: UInt!
    var dbCurrentUserHandle: UInt!
    
    var stateDidChangeListenerInvocationCount = 0
    
    var postsOrderedBy : String = "dateOfCreate"
    
    var refreshControl: UIRefreshControl!
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var userLabelName: UILabel!
    @IBOutlet weak var userEmailLabel: UILabel!
    @IBOutlet weak var displayNameLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        setAuthObservser(){ (userAutheticated) in
            if userAutheticated {
                CurrentUser.cu.readCurrentUserFromDatabase()
                {
                    self.setCurrentUserLabels()
                    self.setTableView()
                    self.setImagePicker()
                    self.setPostsObserver()
                }
            } else {
                self.performSegue(withIdentifier: "segueFeedToLoginVC", sender: nil)
            }
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
//        print("==[FeedVC].viewWillDisappear : removeAuthStateDidChangeListener \n")
        FIRAuth.auth()?.removeStateDidChangeListener(authStateDidChangeListenerHandle)
        removeDBObservers()
        // what even is better to remove listener? viewWillDisappear or viewDidDisappear
    }
    
    func removeDBObservers(){
        removePostObsever()
        removeUserObsever()
    }
    
    func removePostObsever(){
        if let _ = postsHandle {
            DataService.ds.REF_POSTS.removeObserver(withHandle: postsHandle)
        }
    }
    
    func removeUserObsever(){
        if let _ = usersHandle {
            DataService.ds.REF_POSTS.removeObserver(withHandle: usersHandle)
        }
    }
    
    func setTableView() {
        tableView.delegate = self
        tableView.dataSource = self
        setRefreshControl()
    }
    
    func setRefreshControl() {
        refreshControl = UIRefreshControl.init()
        refreshControl.backgroundColor = UIColor.orange
        refreshControl.tintColor = UIColor.white
        refreshControl.addTarget(self, action: #selector(updateTableView), for: UIControlEvents.valueChanged)
        tableView.refreshControl = refreshControl
    }
    
    func setImagePicker() {
        imagePicker = UIImagePickerController()
        imagePicker.allowsEditing = true
        imagePicker.delegate = self
    }
    
    func updateTableView(){
        tableView.reloadData()
        self.refreshControl.endRefreshing()
    }
    
    func setCurrentUserLabels(){
        userEmailLabel.text = CurrentUser.cu.currentDBUser.email
        displayNameLabel.text = CurrentUser.cu.currentDBUser.userName
        
    }
    
    func setAuthObservser(completion: @escaping (_ userAuthenticated: Bool) -> Void) { // listener for auth change (user login/logount)
        
        authStateDidChangeListenerHandle = FIRAuth.auth()?.addStateDidChangeListener { auth, user in
            
            if let user = user { // User is signed in.

                self.setLocalCurrentUser(user: user)
                completion(true)
                
            } else {
                // No user is signed in.
                self.clearLocalCurrentUser()
                completion(false)
                self.userEmailLabel.text = "No user logged / not yet logged in"
            }
            
            self.stateDidChangeListenerInvocationCount += 1
        }
    }
    
    func setLocalCurrentUser(user: FIRUser){
        CurrentUser.cu.currentFIRUser = user
        CurrentUser.cu.REF_USER_CURRENT = DataService.ds.REF_USERS.child(user.uid)
        CurrentUser.cu.writeFIRUserDataToCurrenDBUser()
        print("==[FeedVC].setAuthObservser() : User logged In : ...Count \(self.stateDidChangeListenerInvocationCount) \n")
    }
    
    func clearLocalCurrentUser(){
        CurrentUser.cu.currentFIRUser = nil
        CurrentUser.cu.REF_USER_CURRENT = nil
        CurrentUser.cu.currentDBUser = nil
        print("==[FeedVC].setAuthObservser() -> clearCurrentUser() : User logged Out/ not yet logged In: ...Count \(self.stateDidChangeListenerInvocationCount) \n")
    }
    
    func setPostsObserver() {
        
        postsHandle = DataService.ds.REF_POSTS.queryOrdered(byChild: postsOrderedBy).observe(.value, with: { (snapshot) in
            if let snapshots = snapshot.children.allObjects as? [FIRDataSnapshot] {
                self.posts = snapshots.map(self.parseSnapshotToPost)
                self.setUserObserver(){
                    self.posts = self.posts.map(self.addUserDataToPost)
                    self.tableView.reloadData()
                }
            }
        }, withCancel: { (error) in
            print("===[FeedVC] DB Error (setupPostsObserver) : \(error)\n")
        })
    }
    
    func parseSnapshotToPost(snap: FIRDataSnapshot) -> Post {
        if let postDict = snap.value as? [String : Any] {
            return Post(postKey: snap.key, postData: postDict) // not shure if 3 strings above required
        } else {
            return Post()
        }
    }
    
    func addUserDataToPost(post: Post) -> Post {
        if let userName = usersDict[post.authorKey]?.userName {
            post.authorName = userName
        }
        
        if let avatarUrl = usersDict[post.authorKey]?.avatarUrl {
            post.authorAvatarUrl = avatarUrl
        }
        
        return post
    }
    
    func setUserObserver(completion: @escaping ()-> Void){
        usersHandle = DataService.ds.REF_USERS.observe(.value, with: { (snapshot) in
            if let snapshots = snapshot.children.allObjects as? [FIRDataSnapshot] {
                self.users = snapshots.map(self.parseSnapshotToUser)
                for user in self.users {
                    self.usersDict[user.userKey!] = user
                }
            }
            completion()
        }, withCancel: { (error) in
            print("===[FeedVC] DB Error (setupPostsObserver) !! : \(error)\n")
            completion()
        })
    }
    
    func parseSnapshotToUser(snap: FIRDataSnapshot) -> User {
        if let userDict = snap.value as? [String : Any] {
            return User(userKey: snap.key, userData: userDict)
        } else {
            return User()
        }
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return posts.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        let post = posts[indexPath.row]
        if let cell = tableView.dequeueReusableCell(withIdentifier: "PostCell") as? PostCell {
            cell.configureCell(post: post)
            cell.delegate = self
            return cell
        } else {
            return PostCell()
        }
    }
    
    @IBAction func btnSignOutTapped(_ sender: Any) {
        CurrentUser.cu.currentDBUser = User()
        KeychainWrapper.standard.removeObject(forKey: KEY_UID)
        removeDBObservers()
        try! FIRAuth.auth()?.signOut()
    }
    
    @IBAction func newPostButtonTaped(_ sender: Any) {
        performSegue(withIdentifier: "segueFeedToPostVC", sender: .edit as OpenedFor)
    }
    
    @IBAction func editUserButtonTapped(_ sender: Any) {
        performSegue(withIdentifier: "segueFeedToUserVC", sender: nil)
    }
    
    func callSegueFromCell(myData post: AnyObject) {
        self.performSegue(withIdentifier: "segueFeedToPostVC", sender: post)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "segueFeedToUserVC" {
            if let userVC = segue.destination as? UserVC {
                userVC.openedFor = .edit
            }
        }
        
        if segue.identifier == "segueFeedToPostVC" {
            if let postVC = segue.destination as? PostVC {
                if let post = sender as? Post {
                    postVC.openedFor = .edit
                    postVC.post = post
                } else {
                    postVC.openedFor = .create
                    postVC.post = Post()
                }
    
            }
        }
    }

    @IBAction func sortByTapped(_ sender: UISegmentedControl) {
        let index = sender.selectedSegmentIndex
        switch index {
        case 1:
            postsOrderedBy = "authorKey"
        case 2:
            postsOrderedBy = "authorKey"
        default:
            postsOrderedBy = "dateOfCreate"
        }

        removePostObsever()
        setPostsObserver()

    }

}
