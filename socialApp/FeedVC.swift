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
    
    private var authStateDidChangeListenerHandle: FIRAuthStateDidChangeListenerHandle?
    private var postsObserverHandle: UInt?
    
    var postsOrderedBy : String = "dateOfCreate"
    var refreshControl: UIRefreshControl!
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var userLabelName: UILabel!
    @IBOutlet weak var userEmailLabel: UILabel!
    @IBOutlet weak var displayNameLabel: UILabel!
    
    
    var authObservserCompletionInvocationCount = 0
    
    override func viewWillAppear(_ animated: Bool) {

        setAuthObservser(){ userAutheticated in
            if userAutheticated {
                
                if self.authObservserCompletionInvocationCount > 0 {
                    print("====[FeddVC].viewWillAppear: authObservserCompletionInvocationCount = \(self.authObservserCompletionInvocationCount) \n")
 
                    CurrentUser.cu.readCurrentUserFromDatabase() {
                        DispatchQueue.main.async {
                            self.setCurrentUserLabels()
                        }
                        self.setTableView()
                        self.setImagePicker()
                        self.setPostsObserver()
                    }
                }
            } else {
                //self.authObservserCompletionInvocationCount = 0
                self.performSegue(withIdentifier: "segueFeedToLoginVC", sender: nil)
            }
            self.authObservserCompletionInvocationCount += 1
        }
    }

////////////////////////////////
//  Seting TableView
////////////////////////////////
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
    
    func updateTableView(){
        tableView.reloadData()
        self.refreshControl.endRefreshing()
    }
    
    
////////////////////////////////
//
////////////////////////////////
    func setImagePicker() {
        imagePicker = UIImagePickerController()
        imagePicker.allowsEditing = true
        imagePicker.delegate = self
    }

    
    func setCurrentUserLabels(){
        userEmailLabel.text = CurrentUser.cu.currentDBUser.email
        displayNameLabel.text = CurrentUser.cu.currentDBUser.userName
        
    }
    
////////////////////////////////
//  Reading Current User
////////////////////////////////
    
    func setAuthObservser(completion: @escaping (_ userAuthenticated: Bool) -> Void) { // listener for auth change (user login/logount)
        
        authStateDidChangeListenerHandle = FIRAuth.auth()?.addStateDidChangeListener {  auth, user in
            
            if let user = user { // User is signed in.
                self.setLocalCurrentUser(user: user)
                completion(true)
                
            } else {// No user is signed in.
                self.clearLocalCurrentUser()
                completion(false)
                self.userEmailLabel.text = "No user logged / not yet logged in"
            }
        }
    }
    
    func setLocalCurrentUser(user: FIRUser){
        CurrentUser.cu.currentFIRUser = user
        CurrentUser.cu.REF_USER_CURRENT = DataService.ds.REF_USERS.child(user.uid)
        CurrentUser.cu.writeFIRUserDataToCurrenDBUser()
    }
    
    func clearLocalCurrentUser(){
        CurrentUser.cu.currentFIRUser = nil
        CurrentUser.cu.REF_USER_CURRENT = nil
        CurrentUser.cu.currentDBUser = nil
    }
    
////////////////////////////////
//  Reading posts and users
////////////////////////////////
    
    var postsObserverCompletionInvocationCount = 0
    
    func setPostsObserver() {
        
        if postsObserverHandle == nil {
            postsObserverHandle = DataService.ds.REF_POSTS.queryOrdered(byChild: postsOrderedBy).observe(.value, with: { (snapshot) in
                    if let snapshots = snapshot.children.allObjects as? [FIRDataSnapshot] {
                        self.posts = snapshots.map(self.mapSnapshotToPost)
                        
                        ///
                        self.setUserSingleObserver(){
                            self.posts = self.posts.map(self.addUserDataToPost)
                            DispatchQueue.main.async {
                                self.tableView.reloadData()
                            }
                        }
                    }

                
            }, withCancel: { (error) in
                print("===[FeedVC] DB Error (setupPostsObserver) : \(error)\n")
            })
        }
    }
    
    func mapSnapshotToPost(snap: FIRDataSnapshot) -> Post {
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
    
    func setUserSingleObserver(completion: @escaping ()-> Void){
        DataService.ds.REF_USERS.observeSingleEvent(of: .value, with: { (snapshot) in
           
            if let snapshots = snapshot.children.allObjects as? [FIRDataSnapshot] {
                self.users = snapshots.map(self.mapSnapshotToUser)
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
    
    func mapSnapshotToUser(snap: FIRDataSnapshot) -> User {
        if let userDict = snap.value as? [String : Any] {
            return User(userKey: snap.key, userData: userDict)
        } else {
            return User()
        }
    }
    
////////////////////////////////

    
    @IBAction func btnSignOutTapped(_ sender: Any) {
        CurrentUser.cu.currentDBUser = User()
        KeychainWrapper.standard.removeObject(forKey: KEY_UID)
        removePostObserver()
        try! FIRAuth.auth()?.signOut()
    }
    
    @IBAction func newPostButtonTaped(_ sender: Any) {
        performSegue(withIdentifier: "segueFeedToPostVC", sender: .edit as OpenedFor)
    }
    
    @IBAction func editUserButtonTapped(_ sender: Any) {
        performSegue(withIdentifier: "segueFeedToUserVC", sender: nil)
    }
    
    func callEditSegueFromCell(myData post: AnyObject) {
        self.performSegue(withIdentifier: "segueFeedToPostVC", sender: post)
    }

    func callCommentSegueFromCell(myData post: AnyObject) {
        self.performSegue(withIdentifier: "segueFeedToCommentsVC", sender: post)
    }
    
////////////////////////
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
        
        if segue.identifier == "segueFeedToCommentsVC" {

            if let commentsVC = segue.destination as? CommentsVC {
                if let post = sender as? Post {
                    commentsVC.post = post
                } else {
                    print("===[FeedVC].prepareForSegue : segueFeedToCommentsVC : Can't add comments withouth post\n")
                }
                
            }
        }
    }

//////////////////////
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
        
        // reload snapshot with differen ordering
        removePostObserver()
        setPostsObserver()

    }

    
////////////////////////////////
//  Removing listeners
////////////////////////////////
    
    override func viewWillDisappear(_ animated: Bool) {
        
        removeAuthObserver()
        removePostObserver()

    }
    
    func removeAuthObserver(){
        if let handle = authStateDidChangeListenerHandle {
            FIRAuth.auth()?.removeStateDidChangeListener(handle)
            authStateDidChangeListenerHandle = nil
        //self.authObservserCompletionInvocationCount = 0
        }
    }
    

    func removePostObserver(){
        if let handle = postsObserverHandle {
            DataService.ds.REF_POSTS.removeObserver(withHandle: handle)
            postsObserverHandle = nil
            
        }
    }
    
    @IBAction func testBtnTapped(_ sender: Any) {
        print("=== Test\n")
        
    }
/////////////////////
}
