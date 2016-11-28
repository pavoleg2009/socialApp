//
//  PostCell.swift
//  socialApp
//
//  Created by Oleg Pavlichenkov on 09/11/2016.
//  Copyright © 2016 Oleg Pavlichenkov. All rights reserved.
//

import UIKit
import Firebase



class PostCell: UITableViewCell {
    
    var delegate: MyCustomCellDelegator!
    
    var post: Post!
    var likesRef: FIRDatabaseReference!


    ///@IBOutlet weak var profileImage: CircleView!

    @IBOutlet weak var authorLabel: UILabel!
    @IBOutlet weak var postImage: UIImageView!
    
    @IBOutlet weak var userAvatarImage: CircleView!
    @IBOutlet weak var caption: UITextView!
    @IBOutlet weak var likeImage: UIImageView!
    
    @IBOutlet weak var likeLbl: UILabel!
    @IBOutlet weak var editPostButton: UIButton!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(likeTapped))
        tap.numberOfTapsRequired = 1
        likeImage.addGestureRecognizer(tap)
        likeImage.isUserInteractionEnabled = true
        
       
    }

    func configureCell(post: Post, img: UIImage? = nil) {
        self.post = post
        
        if let userRef = DataService.ds.REF_USER_CURRENT {
            self.likesRef = userRef.child("likes").child(post.postKey)
        }
        
        self.caption.text = post.caption
        self.likeLbl.text = "\(post.likes)"
        self.authorLabel.text = post.authorKey
      //  self.editPostButton.isHidden = post.authorKey != DataService.ds.currentDBUser.userKey
      //  print("==== post.authorKey = \(post.authorKey) ==== DataService.ds.currentDBUser.userKey = \(DataService.ds.currentDBUser.userKey)\n")
        
        //load image
        if img != nil {
            self.postImage.image = img
        } else {
            
            if post.imageUrl != "" {
                let ref = FIRStorage.storage().reference(forURL: post.imageUrl)
                ref.data(withMaxSize: 2 * 1024 * 1024 /* 2 Megabytes*/, completion: { (data, error) in
                    if error != nil {
                        print(" === Unable to download image from Firebase storage: \(error.debugDescription) ")
                    } else {
                        //print(" === Image downloaded from Firebase storage" )
                        if let imgData = data {
                            if let img = UIImage(data: imgData) {
                                self.postImage.image = img
                                DataService.imageCache.setObject(img, forKey: post.imageUrl as NSString)
                            }
                        }
                    }
                })
            } else { // if no valid imageUrl
                self.postImage.image = UIImage(named: "thumbnail-default")
            }
        }
        
        // load author
        
        DataService.ds.REF_USERS.child("/\(post.authorKey)/").observeSingleEvent(of: .value, with: { snapshot in
            if let _ = snapshot.value as? NSNull {
                print("=== User nof found in Users - (snapshot = nil)")
            } else {
                let snapDict = snapshot.value as? [String : AnyObject]
                if let authorName = snapDict?["userName"] as? String {
                    post.authorName = authorName
                    self.authorLabel.text = authorName
                } else {
                    post.authorName = ""
                    self.authorLabel.text = "Author Unknown"
                }
                
                if let authorAvatarUrl = snapDict?["avatarUrl"] as? String {
                    post.authorAvatarUrl = authorAvatarUrl
                    
                    //
                    //load image
                    if authorAvatarUrl != "" {
//                    if img != nil {
//                        self.postImage.image = img
//                    } else {
                        let ref = FIRStorage.storage().reference(forURL: authorAvatarUrl)
                        ref.data(withMaxSize: 2 * 1024 * 1024 /* 2 Megabytes*/, completion: { (data, error) in
                            if error != nil {
                                //print(" === Unable to download image from Firebase storage: \(error.debugDescription) ")
                            } else {
                                //print(" === Image downloaded from Firebase storage" )
                                if let imgData = data {
                                    if let img = UIImage(data: imgData) {
                                        self.userAvatarImage.image = img
                                        DataService.imageCache.setObject(img, forKey: authorAvatarUrl as NSString)
                                    }
                                }
                            }
                        })
                    } else {

                    }
                 //   }
                    
                } else {
                    //self.authorLabel.text = "Author Unknown"
                }
                
            }
        
        })
        
        // load likes
        likesRef.observeSingleEvent(of: .value, with: { (snapshot) in
        
            if let _ = snapshot.value as? NSNull {
                self.likeImage.image = UIImage(named: "empty-heart")
            } else {
                self.likeImage.image = UIImage(named: "filled-heart")
            }
        })
    }
    
    func likeTapped(sender: UITapGestureRecognizer) {
        
        // load likes
        
        likesRef.observeSingleEvent(of: .value, with: { (snapshot) in
            
            if let _ = snapshot.value as? NSNull {
                self.likeImage.image = UIImage(named: "filled-heart")
                self.post.adjustLike(addLike: true)
                self.likesRef.setValue(true)
                
            } else {
                self.likeImage.image = UIImage(named: "empty-heart")
                self.post.adjustLike(addLike: false)
                self.likesRef.removeValue()
            }
        })
    }
    
    @IBAction func editPostButtonTapped(_ sender: Any) {
        
        if(self.delegate != nil){ //Just to be safe.
            self.delegate.callSegueFromCell(myData: post as AnyObject)
        }
        
    }


}
