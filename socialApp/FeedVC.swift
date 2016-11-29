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
                print("===[FeedVC].viewWillAppear() : setAuthObservser() completion: User authenicated, continue init\n")
                DataService.ds.readCurrentUserFromDatabase()
                {
                    self.setCurrentUserLabels()
                    self.setTableView()
                    self.setImagePicker()
                    self.setPostsObserver()
                }
            } else {
                print("===[FeedVC].viewWillAppear() : setAuthObservser() completion: No user authenicated, go to loginVC\n")
                self.performSegue(withIdentifier: "segueFeedToLoginVC", sender: nil)
            }
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        print("==[FeedVC].viewWillDisappear : removeAuthStateDidChangeListener \n")
        FIRAuth.auth()?.removeStateDidChangeListener(authStateDidChangeListenerHandle)
        
        // what even is better to remove listener? viewWillDisappear or viewDidDisappear
    }

    
    override func viewDidDisappear(_ animated: Bool) {
        //remove listeners
        if let _ = postsHandle {
            DataService.ds.REF_POSTS.removeObserver(withHandle: postsHandle)
        }
        
        if let _ = usersHandle {
            DataService.ds.REF_POSTS.removeObserver(withHandle: usersHandle)
        }
    }
    
    func setTableView() {
        tableView.delegate = self
        tableView.dataSource = self
    }
    
    func setImagePicker() {
        imagePicker = UIImagePickerController()
        imagePicker.allowsEditing = true
        imagePicker.delegate = self
    }
    
    func setCurrentUserLabels(){
        userEmailLabel.text = DataService.ds.currentDBUser.email
        displayNameLabel.text = DataService.ds.currentDBUser.userName
        
    }
    
    func setAuthObservser(completion: @escaping (_ userAuthenticated: Bool) -> Void) { // listener for auth change (user login/logount)
        
        authStateDidChangeListenerHandle = FIRAuth.auth()?.addStateDidChangeListener { auth, user in
            
            if let user = user { // User is signed in.

                DataService.ds.currentFIRUser = user
                DataService.ds.writeFIRUserDataToCurrenDBUser()
                print("==[FeedVC].setAuthObservser() : User logged In : ...Count \(self.stateDidChangeListenerInvocationCount) \n")
                completion(true)
                
            } else {
                // No user is signed in.
                DataService.ds.currentFIRUser = nil
                DataService.ds.currentDBUser = nil
                print("==[FeedVC].setAuthObservser() : User logged Out/ not yet logged In: ...Count \(self.stateDidChangeListenerInvocationCount) \n")
                completion(false)
                self.userEmailLabel.text = "No user logged / not yet logged in"
            }
            
            self.stateDidChangeListenerInvocationCount += 1
        }
    }

    func setPostsObserver() {
        
        postsHandle = DataService.ds.REF_POSTS.queryOrdered(byChild: postsOrderedBy).observe(.value, with: { (snapshot) in
            if let snapshots = snapshot.children.allObjects as? [FIRDataSnapshot] {
                self.posts = snapshots.map(self.parseSnapshotToPost)//.map(self.addAutorInfoToPost)
                //read authorName and authorAvatarUrl here, not in configure Cell
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
//        var tempPost = post
        
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
                // not working %((
                //self.usersDict = self.users.map({($0.userKey!, $0)})
                
                for user in self.users {
                    self.usersDict[user.userKey!] = user
                }
                
                
//                self.users = snapshots.map(self.parseSnapshotToUser)
                
            }
            completion()
        }, withCancel: { (error) in
            print("===[FeedVC] DB Error (setupPostsObserver) : \(error)\n")
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
    
//    func populateUsersToUserDict(user: User) -> (String, User){
//        return (user.userKey, user)
//    }
    
//    func addAutorInfoToPost(post: Post) -> Post {
//        
//        if let authorKey = post.authorKey as? String {
//            let tempPost = post
//            
//            return tempPost
//        } else {
//            return post
//        }
//    }

    
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
        DataService.ds.currentDBUser = User()
        KeychainWrapper.standard.removeObject(forKey: KEY_UID)
        print("==[FeedVC].btnSignOutTapped: ID removed from KeyChain \n")
        try! FIRAuth.auth()?.signOut()
        print("==[FeedVC].btnSignOutTapped: LogOut from Firebase \n")

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
        
        print("==[FeedVC].sortByTapped() : \(index) : \(sender.titleForSegment(at: index))\n")
        setPostsObserver()

    }

}
