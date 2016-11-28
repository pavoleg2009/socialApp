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
    var imagePicker: UIImagePickerController!
    var imageSelected = false
    
    private var authStateDidChangeListenerHandle: FIRAuthStateDidChangeListenerHandle!
    var postsHandle: UInt!
    var dbCurrentUserHandle: UInt!
    
    
    
    
    /** @fn removeAuthStateDidChangeListener:
     @brief Unregisters a block as an "auth state did change" listener.
     @param listenerHandle The handle for the listener.
     */
    
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var userLabelName: UILabel!
    @IBOutlet weak var addImageImage: CircleView!
    @IBOutlet weak var captionField: UITextField!
    
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
    
    func setAuthObservser(completion: @escaping (_ userAuthenticated: Bool) -> Void) { // listener for auth change (user login/logount)
        
        authStateDidChangeListenerHandle = FIRAuth.auth()?.addStateDidChangeListener { auth, user in
            
            if let user = user { // User is signed in.

                DataService.ds.currentFIRUser = user
                DataService.ds.writeFIRUserDataToCurrenDBUser()
                print("==[FeedVC].setAuthObservser() : User logged In n")
                completion(true)
                
            } else {
                // No user is signed in.
                DataService.ds.currentFIRUser = nil
                DataService.ds.currentDBUser = nil
                print("==[FeedVC].setAuthObservser() : User logged Out/ not yet logged In: \n")
                completion(false)
                self.userEmailLabel.text = "No user logged / not yet logged in"
            }
        }
    }

    
    func setPostsObserver() {
        postsHandle = DataService.ds.REF_POSTS.observe(.value, with: { (snapshot) in
            if let snapshot = snapshot.children.allObjects as? [FIRDataSnapshot] {
                self.posts = []
                for snap in snapshot {
                    if let postDict = snap.value as? Dictionary<String, Any> {
                        let key = snap.key
                        let post = Post(postKey: key, postData: postDict)
                        self.posts.append(post)
                    }
                }
            }
            self.tableView.reloadData()
        }, withCancel: { (error) in
            print("=== [FeedVC] DB Error (setupPostsObserver) ====: \(error)\n")
        })
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        

    }
    
    override func viewDidDisappear(_ animated: Bool) {
        //remove listeners
        if let _ = postsHandle {
            DataService.ds.REF_POSTS.removeObserver(withHandle: postsHandle)
        print("====[FeedVC].viewDidDisappear : Posts observer removed\n")
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
         
            if let image = DataService.imageCache.object(forKey: post.imageUrl as NSString) {
                cell.configureCell(post: post, img: image)
                
            } else {
                cell.configureCell(post: post)

            }
            cell.delegate = self
            return cell
        } else {
            return PostCell()
        }

    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        if let image = info[UIImagePickerControllerEditedImage] as? UIImage {
            addImageImage.image = image
            imageSelected = true
        } else {
            print(" Invalid media selected ")
        }
        imagePicker.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func btnSignOutTapped(_ sender: Any) {
        DataService.ds.currentDBUser = User()
        KeychainWrapper.standard.removeObject(forKey: KEY_UID)
        print("=== [FeedVC].btnSignOutTapped: ID removed from KeyChain \n")
        try! FIRAuth.auth()?.signOut()
        print("=== [FeedVC].btnSignOutTapped:  LogOut from Firebase \n")

    }
    
    @IBAction func addImageTapped(_ sender: Any) {
        // present(imagePicker, animated: true, completion: nil)
        performSegue(withIdentifier: "segueFeedToPostVC", sender: .create as OpenedFor)
    }

    @IBAction func postButtonTapped(_ sender: Any) {
        performSegue(withIdentifier: "segueFeedToPostVC", sender: .edit as OpenedFor)
        
        
//        guard let caption = captionField.text, caption != "" else {
//            print(" === Cation must be entered ")
//            return
//        }
//        
//        guard let image = addImageImage.image, imageSelected == true else {
//            print(" === Image must be selected ")
//            return
//        }
//        
//        if let imageDada = UIImageJPEGRepresentation(image, 0.2) {
//            
//            let imageUid = NSUUID().uuidString
//            let metadata = FIRStorageMetadata()
//            metadata.contentType = "image/jpeg"
//
//            DataService.ds.REF_POST_IMAGES.child(imageUid).put(imageDada, metadata: metadata) { (metadata, error) in
//                if error != nil {
//                    print(" === Unable to upload image to Firebase Storage: \(error.debugDescription) ")
//                } else {
//                    
//                    let downloadURL = metadata?.downloadURL()?.absoluteString
//                    print(" === Successfully upload image to Firebase Storage with URL: \(downloadURL) ")
//                    if let url = downloadURL {
//                        self.savePostToFirebase(imageUrl: url)
//                    } else {
//                        print(" === Image URL is empty ")
//                    }
//                }
//            }
//        }
    }
    
    
    @IBAction func editUserButtonTapped(_ sender: Any) {
        
        performSegue(withIdentifier: "segueFeedToUserVC", sender: nil)
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

    @IBAction func testButtonClick(_ sender: Any) {
        
        
    }
    
//    func editPostInPostVC() {
//        //performSegue(withIdentifier: "segueFeedToUserVC", sender: nil)
//        print("=== edit post: pergorm segue from cell")
//    }
//    
//    func makePostEditSeguer(forPost post: Post) -> () -> Void {
//        var currPost = post
//        func postSeguer() -> Void {
//        
//            print("=== from segure for: \(post.caption)\n")
//            performSegue(withIdentifier: "segueFeedToPostVC", sender: post)
//            return
//        }
//        return postSeguer
//    }
//    
    

    
    func callSegueFromCell(myData post: AnyObject) {
        //try not to send self, just to avoid retain cycles(depends on how you handle the code on the next controller)
        self.performSegue(withIdentifier: "segueFeedToPostVC", sender: post)
        //print("=== \(post)")
        
    }
    
}
