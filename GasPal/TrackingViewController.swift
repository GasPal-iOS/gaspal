//
//  TrackingViewController.swift
//  GasPal
//
//  Created by Kumawat, Diwakar on 4/28/17.
//  Copyright © 2017 Tyler Hackley Lewis. All rights reserved.
//

import UIKit

class TrackingViewController: UIViewController {
    
    @IBOutlet weak var headerView: Header!

    override func viewDidLoad() {
        super.viewDidLoad()
        print("TrackingViewController")
        
        headerView.title = "Tracking"
        headerView.doShowCameraIcon = true
        headerView.doShowAddIcon = true
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}