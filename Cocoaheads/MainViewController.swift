//
//  MainViewController.swift
//  Cocoaheads
//
//  Created by Harish Subramanium on 2/11/2015.
//  Copyright © 2015 private. All rights reserved.
//

import UIKit
import RxSwift

class MainViewController: UIViewController {
    
    override func viewDidLoad() {
        
        interval(1, MainScheduler.sharedInstance)
        .subscribeNext { (num) -> Void in
            NSNotificationCenter.defaultCenter().postNotificationName("Ticker", object: nil)
        }
        
    }
    
}