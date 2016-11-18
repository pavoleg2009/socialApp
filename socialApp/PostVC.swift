//
//  PostVC.swift
//  socialApp
//
//  Created by Oleg Pavlichenkov on 17/11/2016.
//  Copyright © 2016 Oleg Pavlichenkov. All rights reserved.
//

import UIKit
import Firebase

class PostVC: UIViewController {
    
    var openedFor: OpenedFor = .insert
    var post: Post!
    var likesRef: FIRDatabaseReference!
    
    
    @IBOutlet weak var lbl: UILabel!
    @IBOutlet weak var openedForLabel: UILabel!
    @IBOutlet weak var postCaptionField: UITextField!
    
    @IBOutlet weak var postImage: UIImageView!
    
    @IBOutlet weak var deleteButton: MyButton!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        if openedFor == .edit {
            configureViewForEditPost()
        } else {
           configureViewForNewPost()
        }
    }

    func configureViewForNewPost() {
        openedForLabel.text = "New! Post"
    }
    
    func configureViewForEditPost() {
        openedForLabel.text = "Edit Post"
        postCaptionField.text = post.caption
        lbl.text = post.imageUrl
    }
    
    @IBAction func cancelButtonTapped(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }

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
        
        
        
      //  DataService.ds.REF_POST_IMAGES.child(post.imageUrl).delete { (error) in
            
        FIRStorage.storage().reference(forURL: post.imageUrl).delete(completion: { (error) in
            if error != nil {
                print("==== Error trting to delete post image from Storage: \(self.post.imageUrl) \n ===== \(error.debugDescription)")
                
                // cleare cache
                FeedVC.imageCache.removeObject(forKey: self.post.imageUrl as NSString)
            } else {
                print("==== Post image deleted from Storage, going to delete post")
            }
            })     
            
        DataService.ds.REF_POSTS.child(self.post.postKey).removeValue { (error, ref) in
            if error != nil {
                print(" ==== Error \(error.debugDescription)\n ===== deleting post: \(ref.description())\n")
            } else {
                print(" ==== Post deleted: \(ref.description())\n")
                self.dismiss(animated: true, completion: nil)
            }
        
        }
            
    
    }
}
