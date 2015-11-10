//
//  ViewController.swift
//  Cocoaheads
//
//  Created by Harish Subramanium on 2/11/2015.
//  Copyright © 2015 private. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

class SimpleLoginViewController: UIViewController {

    
    @IBOutlet weak var username: UITextField!
    @IBOutlet weak var password: UITextField!
    @IBOutlet weak var submitButton: UIButton!
    
    private let disposeBag = DisposeBag()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        viewLogic()
    }
    
    // Simple Implementation - Enable Submit Button when both username and password have content
    func viewLogic() {
        
        let username$ = username.rx_text
        let password$ = password.rx_text
        
        // Enable submit button when both username and password have text
        let usernameCount$ = username$.map({ $0.characters.count })
        let passwordCount$ = password$.map({ $0.characters.count })
        
        combineLatest(usernameCount$, passwordCount$, resultSelector: { $0 > 0 && $1 > 0 }) // Returns value as a tuple (usernameCount, passwordCount)
        .subscribeNext({ enabled -> Void in
            self.submitButton.enabled = enabled;
            print("Submit \(enabled ? "Enabled" : "Disabled")")
        })
        
    }


}

