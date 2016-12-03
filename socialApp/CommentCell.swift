//
//  CommentCell.swift
//  socialApp
//
//  Created by Oleg Pavlichenkov on 02/12/2016.
//  Copyright © 2016 Oleg Pavlichenkov. All rights reserved.
//

import UIKit

class CommentCell: UITableViewCell {
    
    var comment: Comment!
    
    var authorAvatarImageView: CircleView = {
        let imageView = CircleView()
        imageView.image = UIImage(named: "default-avatar-catty")
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFill
        
        return imageView
    }()
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()

        setLabels()
    }
    
    func setLabels(){
        let leftMargin: CGFloat = 80
        let rightMargin: CGFloat = 20
        textLabel?.frame = CGRect(x: leftMargin, y: textLabel!.frame.origin.y-2, width: (self.frame.width - leftMargin - rightMargin), height: textLabel!.frame.height)
        detailTextLabel?.frame = CGRect(x: leftMargin, y: detailTextLabel!.frame.origin.y+2, width: (self.frame.width - leftMargin - rightMargin), height: detailTextLabel!.frame.height)
    }
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: .subtitle, reuseIdentifier: reuseIdentifier)
        
        setTextLabel()
        addSubview(authorAvatarImageView)
        setAuthorAvatarImageView()
        
    }
    
    func setTextLabel(){
        
    }
    
    func setAuthorAvatarImageView() {
        let avatarMargin : CGFloat = 8
        authorAvatarImageView.leftAnchor.constraint(equalTo: self.leftAnchor, constant: avatarMargin).isActive = true
        authorAvatarImageView.heightAnchor.constraint(equalTo: self.heightAnchor, constant: -(avatarMargin * 2)).isActive = true
        authorAvatarImageView.widthAnchor.constraint(equalTo: authorAvatarImageView.heightAnchor, constant: 0).isActive = true
        authorAvatarImageView.centerYAnchor.constraint(equalTo: self.centerYAnchor, constant: 0).isActive = true
        
    }
    
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been imolemented")
    }
    
    func configureCell(comment: Comment){
        self.comment = comment
        
        self.textLabel?.text = comment.caption
        
        if let name = comment.authorName {
            
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd HH:mm"
            let dateStr = dateFormatter.string(from: comment.dateOfCreate)
            
            self.detailTextLabel?.text = "[\(dateStr)]: \(name)"
        }
        
        
        
        if let url = comment.authorAvatarUrl {
            DataService.ds.readImageFromStorage(imageUrl: url, completion: { image in
                DispatchQueue.main.async {
                    self.authorAvatarImageView.image = image
                }
            })
        }
        
        
    }
}
