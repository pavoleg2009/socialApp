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

class FeedVC: UIViewController, UITableViewDelegate, UITableViewDataSource, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    var currentUser: User!
    var posts = [Post]()
    var imagePicker: UIImagePickerController!
    static var imageCache: NSCache<NSString, UIImage> = NSCache()
    var imageSelected = false
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var userLabelName: UILabel!
    @IBOutlet weak var addImageImage: CircleView!
    @IBOutlet weak var captionField: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
//        userLabelName.text = currentUser.userName
  //      print("=== currentUser.userName: \(currentUser.userName)")
        tableView.delegate = self
        tableView.dataSource = self
        
        imagePicker = UIImagePickerController()
        imagePicker.allowsEditing = true
        imagePicker.delegate = self
        
        DataService.ds.REF_POSTS.observe(.value, with: { (snapshot) in
            if let snapshot = snapshot.children.allObjects as? [FIRDataSnapshot] {
                self.posts = []
                for snap in snapshot {
                    //print("=== SNAP: \(snap)")
                    if let postDict = snap.value as? Dictionary<String, Any> {
                        let key = snap.key
                        let post = Post(postKey: key, postData: postDict)
                        self.posts.append(post)
                    }
                }
            }
            self.tableView.reloadData()
        })
        
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
            
//            var image: UIImage!
            
            if let image = FeedVC.imageCache.object(forKey: post.imageUrl as NSString) {
                print("=== load image from cache")
                cell.configureCell(post: post, img: image)
                return cell
            } else {
                cell.configureCell(post: post)
                return cell
            }
            
        } else {
            return PostCell()
        }

    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        if let image = info[UIImagePickerControllerEditedImage] as? UIImage {
            addImageImage.image = image
            imageSelected = true
        } else {
            print("Invalid media selected")
        }
        imagePicker.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func btnSignOutTapped(_ sender: Any) {
        let _ = KeychainWrapper.standard.remove(key: KEY_UID)
        print("=== ID removed from KeyChain")
        try! FIRAuth.auth()?.signOut()
        print("=== LogOut from Firebase")
        performSegue(withIdentifier: "goToSignInVC", sender: nil)
    }
    
    @IBAction func addImageTapped(_ sender: Any) {
        
        present(imagePicker, animated: true, completion: nil)
        
        
    }

    @IBAction func postButtonTapped(_ sender: Any) {
        
        guard let caption = captionField.text, caption != "" else {
            print("=== Cation must be entered")
            return
        }
        
        guard let image = addImageImage.image, imageSelected == true else {
            print("=== Image must be selected")
            return
        }
        
        if let imageDada = UIImageJPEGRepresentation(image, 0.2) {
            
            let imageUid = NSUUID().uuidString
            let metadata = FIRStorageMetadata()
            metadata.contentType = "image/jpeg"
            
            DataService.ds.REF_POST_IMAGES.child(imageUid).put(imageDada, metadata: metadata) { (metadata, error) in
                if error != nil {
                    print("=== Unable to upload image to Firebase Storage: \(error.debugDescription)")
                } else {
                    
                    let downloadURL = metadata?.downloadURL()?.absoluteString
                    print("=== Successfully upload image to Firebase Storage with URL: \(downloadURL)")
                    if let url = downloadURL {
                        self.savePostToFirebase(imageUrl: url)
                    } else {
                        print("=== Image URL is empty")
                    }
                }
            }
        }
    }
    
    func savePostToFirebase(imageUrl: String) {
        let post: Dictionary<String, Any> = [
            "caption": captionField.text!,
            "imageUrl": imageUrl,
            "likes": 0
        ]
        
        let firebasePost = DataService.ds.REF_POSTS.childByAutoId()
        firebasePost.setValue(post)
        
        captionField.text = ""
        imageSelected = false
        addImageImage.image = UIImage(named: "add-image")
        
        tableView.reloadData()
        
    }


}
