//
//  NotificationDisposableViewController.swift
//  Cocoaheads
//
//  Created by Harish Subramanium on 2/11/2015.
//  Copyright © 2015 private. All rights reserved.
//

import UIKit
import RxSwift

class NotificationDisposableViewController: UIViewController {
    
    private let disposeBag = DisposeBag()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        viewLogic()
    }
    
    
    func viewLogic() {
        
        let currentDate = NSDate()
        
        NSNotificationCenter.defaultCenter().rx_notification("Ticker")
        .subscribeNext({ _ -> Void in
            print("Ticker Triggered. View Started On : \(currentDate)")
        })
        .addDisposableTo(disposeBag)
    }
}
