//
//  PostCell.swift
//  socialApp
//
//  Created by Oleg Pavlichenkov on 09/11/2016.
//  Copyright © 2016 Oleg Pavlichenkov. All rights reserved.
//

import UIKit

class PostCell: UITableViewCell {
    
    var post: Post!

    @IBOutlet weak var profileImage: CircleView!
    @IBOutlet weak var userLbl: UILabel!
    @IBOutlet weak var postImage: UIImageView!
   
    @IBOutlet weak var caption: UITextView!
    @IBOutlet weak var likeLbl: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    func configureCell(post: Post) {
        
        self.caption.text = post.caption
        self.likeLbl.text = "\(post.likes)"
        
        
        
    }

}
