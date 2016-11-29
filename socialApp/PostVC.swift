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
        if isEnteredDataValidForNewPost() {
            DataService.ds.createImageInStorage(image: postImage.image, ref: DataService.ds.REF_POST_IMAGES) {createdImageURL in
                self.preparePostDataForCreate(postImageUrl: createdImageURL) { (newPostRef, postData) in
                    self.updatePostInDatabase(firebasePostRef: newPostRef, postData: postData)
                }
            }
        } else {
            print("===[PostVC].createPostTapped() : New Post data is invalid. Caption must be enterend and Image smust be selected\n")
        }
    }
    
    func isEnteredDataValidForNewPost() -> Bool {
        // postCaption (not empty)
        // image selected
        return postCaptionField.text != "" && imageSelectedOrChanged

    }
    
    func preparePostDataForCreate(postImageUrl: String?, completion: @escaping(_ firebasePostRef: FIRDatabaseReference, _ postData: Dictionary<String, Any>)->Void){
        
        var postData: [String : Any] = [
            "caption" : postCaptionField.text!,
            "likes" : 0,
            "authorKey" : DataService.ds.currentDBUser.userKey!,
            "dateOfCreate": [".sv": "timestamp"],
            "dateOfUpdate": [".sv": "timestamp"]
        ]
        
        if let url = postImageUrl, url != "" {
            postData["imageUrl"] = url
        }
        
        let newPostRef = DataService.ds.REF_POSTS.childByAutoId()

        completion(newPostRef, postData)
    }
    
    func updatePostInDatabase(firebasePostRef: FIRDatabaseReference, postData: Dictionary<String, Any>) {
        
        firebasePostRef.setValue(postData, withCompletionBlock: {(error, dbReference) in
            if error != nil {
                // error whily trying to save posr (permiossion or smth else)
                print("====[].savePostToFirebase(.setValue completion): Error while trying to save post to Firebase: \(error.debugDescription)\n")
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
        
//!!
    }

    
    func configurePostVCForEdit() {
        postVCCaptionLabel.text = "Edit Post"
        postCaptionField.text = post.caption
        saveButton.setTitle("Save Post", for: [])
        saveButton.addTarget(self, action: #selector(PostVC.savePostTapped(_:)), for: .touchUpInside)
        
    }

////////////////////////////////
// Update Post Info in Database
////////////////////////////////
    
    func savePostTapped(_ sender: Any) {
//!! write here
        
        preparePostDataForUpdate(){postData in
            if let postData = postData {
//                self.updatePostInDatabase(postDataToUpdate: postData)
            }
        }
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
    
    
    func preparePostDataForUpdate(completion: @escaping(Dictionary<String, Any>?) -> Void) {
        //put data from UIControls to post
        
        var postDataToUpdate: [String : Any] = [:]
        
        if postCaptionField.text != "" && postCaptionField.text != post.caption {
            postDataToUpdate["caption"] = postCaptionField.text!
        }
        
        postDataToUpdate["dateOfUpdate"] = [".sv": "timestamp"]
        
        if imageSelectedOrChanged {
           
            DataService.ds.createImageInStorage(image: postImage.image, ref: DataService.ds.REF_POST_IMAGES) {newImageUrl in
                if let url = newImageUrl {
                    if self.post.imageUrl != "" {
                        DataService.ds.deleteImageFromStorage(imageUrl: self.post.imageUrl)
                    }
                    self.post.imageUrl = url
                    print("===[PostVC] \n ")
                    postDataToUpdate["imageUrl"] = url
                    
                    completion(postDataToUpdate)
                } else {
                    //no image added
                    completion(nil)
                }
            }
        } else { // no image changed, but title can be changed
            if postDataToUpdate.count > 0 {
                completion(postDataToUpdate)
            } else {
                completion(nil)
            }
        }
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



