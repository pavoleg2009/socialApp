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
    
    @IBOutlet weak var tableVIew: UITableView!
    @IBOutlet weak var userLabelName: UILabel!
 
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        userLabelName.text = currentUser.userName
        
        tableVIew.delegate = self
        tableVIew.dataSource = self
    }
    
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 3
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
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
