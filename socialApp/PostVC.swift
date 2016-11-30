//
//  PostVC.swift
//  socialApp
//
//  Created by Oleg Pavlichenkov on 17/11/2016.
//  Copyright © 2016 Oleg Pavlichenkov. All rights reserved.
//

import UIKit
import Firebase

class PostVC: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    var openedFor: OpenedFor = .create
    var imagePicker : UIImagePickerController!
    var imageSelectedOrChanged = false
    
    var post: Post!
    var likesRef: FIRDatabaseReference!

    @IBOutlet weak var postVCCaptionLabel: UILabel!
    @IBOutlet weak var postImage: UIImageView!
    @IBOutlet weak var postCaptionField: UITextField!
    @IBOutlet weak var saveButton: MyButton!
    @IBOutlet weak var deleteButton: MyButton!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        setImagePicker()
        
        switch self.openedFor {
        case .edit: // if view opened for editing existing Post
            readPostData(){
                self.configurePostVCForEdit()
                self.loadPostImage() //{}
            }
        default: // if view opened for adding post
            configurePostVCForCreate()
        }
    }
    
////////////////////////////////
// Creating New Post
////////////////////////////////
    
    func configurePostVCForCreate() {
        postVCCaptionLabel.text = "New Post"
        postCaptionField.text = ""
        
        saveButton.setTitle("Create Post", for: [])
        saveButton.addTarget(self, action: #selector(PostVC.createPostTapped(_:)), for: .touchUpInside)
        
        postImage.image = UIImage(named: "thumbnail-default")
    }
    
    func createPostTapped(_ sender: Any) {
        if enteredDataIsValidForNewPost() {
            DataService.ds.createImageInStorage(image: postImage.image, ref: DataService.ds.REF_POST_IMAGES) {createdImageURL in
                self.preparePostDataForCreate(postImageUrl: createdImageURL) { (newPostRef, postData) in
                    self.createPostInDatabase(firebasePostRef: newPostRef, postData: postData)
                }
            }
        } else {
            print("===[PostVC].createPostTapped() : New Post data is invalid. Caption must be enterend and Image smust be selected\n")
        }
    }
    
    func enteredDataIsValidForNewPost() -> Bool {
        // postCaption (not empty)
        // image selected
        return postCaptionField.text != "" && imageSelectedOrChanged

    }
    
    func preparePostDataForCreate(postImageUrl: String?, completion: @escaping(_ firebasePostRef: FIRDatabaseReference, _ postData: [String : Any])->Void){
        
        var postData: [String : Any] = [
            "caption" : postCaptionField.text!,
            "likes" : 0,
            "authorKey" : CurrentUser.cu.currentDBUser.userKey!,
            "dateOfCreate": [".sv": "timestamp"],
            "dateOfUpdate": [".sv": "timestamp"]
        ]
        
        if let url = postImageUrl, url != "" {
            postData["imageUrl"] = url
        }
        
        let newPostRef = DataService.ds.REF_POSTS.childByAutoId()

        completion(newPostRef, postData)
    }
    
    func createPostInDatabase(firebasePostRef: FIRDatabaseReference, postData: [String : Any]) {
        
        firebasePostRef.setValue(postData, withCompletionBlock: {(error, dbReference) in
            if error != nil {
                // error whily trying to save posr (permiossion or smth else)
                print("===[PostVC].savePostToFirebase().setValue completion): Error while trying to save post to Firebase: \(error.debugDescription)\n")
            } else {
                // new post saved successfull
                self.dismiss(animated: true, completion: nil)
            }
        })
    }
    
////////////////////////////////
// Read Post Data From Database
////////////////////////////////
    
    func readPostData(completion: @escaping() -> Void) {
        // in future: reading comments
        completion()
    }
   
    func configurePostVCForEdit() {
        postVCCaptionLabel.text = "Edit Post"
        postCaptionField.text = post.caption
        saveButton.setTitle("Save Post", for: [])
        saveButton.addTarget(self, action: #selector(PostVC.savePostTapped(_:)), for: .touchUpInside)
    }

    func loadPostImage() {
        
        if post.imageUrl != "" {
            DataService.ds.readImageFromStorage(imageUrl: post.imageUrl) { (image) in
                self.postImage.image = image
                return
            }
            
        } else { // if imageUrl is empty
            postImage.image = UIImage(named: "thumbnail-default")
        }
    }
    
////////////////////////////////
// Update Post Info in Database
////////////////////////////////
    
    func savePostTapped(_ sender: Any) {
        if enteredDataIsValidForUpdatePost() {
            if imageSelectedOrChanged {
                tryToDeleteOldImage()
                DataService.ds.createImageInStorage(image: postImage.image, ref: DataService.ds.REF_POST_IMAGES) {createdImageURL in
                    self.preparePostDataForUpdate(postImageUrl: createdImageURL) { (newPostRef, postData) in
                        self.updatePostInDatabase(firebasePostRef: newPostRef, postData: postData)
                    }
                }
            } else {
                preparePostDataForUpdate(postImageUrl: nil) { (newPostRef, postData) in
                    self.updatePostInDatabase(firebasePostRef: newPostRef, postData: postData)
                }
            }
        }
    }
    
    func enteredDataIsValidForUpdatePost() -> Bool {
        return postCaptionField.text != ""
    }
    
    func tryToDeleteOldImage(){
        if post.imageUrl != "" {
            DataService.ds.deleteImageFromStorage(imageUrl: post.imageUrl)
        }
        
    }
    
    func preparePostDataForUpdate(postImageUrl: String?, completion: @escaping(_ firebasePostRef: FIRDatabaseReference, _ postData: [String : Any]) -> Void) {
        //put data from UIControls to post
        
        var postData: [String : Any] = [:]
        
        if postCaptionField.text != "" && postCaptionField.text != post.caption {
            postData["caption"] = postCaptionField.text!
        }
      
        if let url = postImageUrl, url != "" {
            postData["imageUrl"] = url
        }
        
        if postData.count > 0 { // check if has some data to update
            postData["dateOfUpdate"] = [".sv": "timestamp"]
        }
        
        let newPostRef = DataService.ds.REF_POSTS.child(post.postKey)
        completion(newPostRef, postData)
    }

    func updatePostInDatabase(firebasePostRef: FIRDatabaseReference, postData: [String : Any]) {
        
        firebasePostRef.updateChildValues(postData, withCompletionBlock: {(error, dbReference) in
            if error != nil {
                // error whily trying to save posr (permiossion or smth else)
                print("===[PostVC].updatePostInDatabase().pdateChildValues completion): Error while trying update post to Firebase: \(error.debugDescription)\n")
            } else {
                // post updated successfull
                self.dismiss(animated: true, completion: nil)
            }
        })
    }

////////////////////////////////
//  Delete Post
////////////////////////////////
        
    @IBAction func deleteButtonTapped(_ sender: Any) {
        
        // create the alert
        let alert = UIAlertController(title: "UIAlertController", message: "Are you going to delete this awesome post?", preferredStyle: UIAlertControllerStyle.alert)
        
        // add the actions (buttons)
        alert.addAction(UIAlertAction(title: "Delete", style: UIAlertActionStyle.destructive, handler: deletePost))
        alert.addAction(UIAlertAction(title: "Cancel", style: UIAlertActionStyle.cancel, handler: nil))
        
        // show the alert
        self.present(alert, animated: true, completion: nil)
        
    }
        
    func deletePost(_: UIAlertAction) {
        
        if post.imageUrl != "" {
            DataService.ds.deleteImageFromStorage(imageUrl: post.imageUrl)
        }
        
        DataService.ds.REF_POSTS.child(self.post.postKey).removeValue { (error, ref) in
            if error != nil {
                print("====[PostVC].deletePost: Error \(error.debugDescription)\n ===== deleting post: \(ref.description())\n")
            } else {
                print("===[PostVC].deletePost: Post deleted: \(ref.description())\n")
                self.dismiss(animated: true, completion: nil)
            }
        }
    }
        
////////////////////////////////
//  Others
////////////////////////////////

    @IBAction func imageTapped(_ sender: Any) {
        present(imagePicker, animated: true)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        if let image = info[UIImagePickerControllerEditedImage] as? UIImage {
            postImage.image = image
            imageSelectedOrChanged = true
        } else {
            print("====[PostVC].imagePickerController..didFinishPickingMediaWithInfo: Invalid media selected\n")
        }
        imagePicker.dismiss(animated: true, completion: nil)
    }
        
    func setImagePicker() {
        imagePicker = UIImagePickerController()
        imagePicker.allowsEditing = true
        imagePicker.delegate = self
    }
    
    @IBAction func cancelButtonTapped(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
    
////////////////////////////////
}



