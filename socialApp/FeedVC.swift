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

class FeedVC: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    var currentUser: User!
    var posts = [Post]()
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var userLabelName: UILabel!
 
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        userLabelName.text = currentUser.userName
        
        tableView.delegate = self
        tableView.dataSource = self
        
        DataService.ds.REF_POSTS.observe(.value, with: { (snapshot) in
            if let snapshot = snapshot.children.allObjects as? [FIRDataSnapshot] {
                for snap in snapshot {
                    print("=== SNAP: \(snap)")
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
        //print("=== : \(post)")
        
        return tableView.dequeueReusableCell(withIdentifier: "PostCell", for: indexPath) as! PostCell
        

        
        
    }
    
    @IBAction func btmSignOutTapped(_ sender: Any) {
        
        let kcResult = KeychainWrapper.standard.remove(key: KEY_UID)
        print("=== ID removed from KeyChain")
        try! FIRAuth.auth()?.signOut()
        print("=== LogOut from Firebase")
        performSegue(withIdentifier: "goToSignInVC", sender: nil)
 
    }
    
    
    



}
