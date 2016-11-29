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
    
    @IBOutlet weak var userAvatarImage: CircleView!
    @IBOutlet weak var authorLabel: UILabel!
    @IBOutlet weak var likeImage: UIImageView!
    @IBOutlet weak var postImage: UIImageView!
    @IBOutlet weak var postCaptionText: UITextView!
    @IBOutlet weak var likesCountLabel: UILabel!
    @IBOutlet weak var editPostButton: UIButton!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        setLikesTapGuestureRecognition()
    }
    
    func setLikesTapGuestureRecognition(){
        let tap = UITapGestureRecognizer(target: self, action: #selector(likeTapped))
        tap.numberOfTapsRequired = 1
        likeImage.addGestureRecognizer(tap)
        likeImage.isUserInteractionEnabled = true
    }
    
    func configureCell(post: Post) {
        self.post = post
        
        postCaptionText.text = "[\(post.dateOfCreate)] : \(post.caption)"
        likesCountLabel.text = "\(post.likes)"
        authorLabel.text = post.authorName
        
      //  self.editPostButton.isHidden = post.authorKey != DataService.ds.currentDBUser.userKey
        
        if let userRef = DataService.ds.REF_USER_CURRENT {
            likesRef = userRef.child("likes").child(post.postKey)
        }
        
        //load post image and avatar
        
        DataService.ds.readImageFromStorage(imageUrl: post.imageUrl) { (image) in
            self.postImage.image = image
        }
     
        DataService.ds.readImageFromStorage(imageUrl: post.authorAvatarUrl) { image in
            self.userAvatarImage.image = image
        }
        
        // load likes
        likesRef.observeSingleEvent(of: .value, with: { (snapshot) in
        
            if let _ = snapshot.value as? NSNull {
                self.likeImage.image = UIImage(named: "empty-heart")
            } else {
                self.likeImage.image = UIImage(named: "filled-heart")
            }
        })
    }
    
    func loadAutorData(){
        
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
