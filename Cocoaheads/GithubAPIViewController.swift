//
//  GithubAPIViewController.swift
//  Cocoaheads
//
//  Created by Harish Subramanium on 3/11/2015.
//  Copyright © 2015 private. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

import Argo
import Curry

// MARK: Return shared NSURLSession for the related Rx Methods
var LocalURLSession: NSURLSession = {
    
    var config = NSURLSessionConfiguration.defaultSessionConfiguration()
    
    config.HTTPAdditionalHeaders = [
        "Content-Type"  : "application/json",
        "Accept"        : "application/json"
    ];
    
    // Setting a 15 second timeout for all requests
    config.timeoutIntervalForRequest = 15
    
    return NSURLSession(configuration: config)
    
}()


func random(range: Range<Int> ) -> Int {
    
    var offset = 0
    
    if range.startIndex < 0 {
        offset = abs(range.startIndex)
    }
    
    let mini = UInt32(range.startIndex + offset)
    let maxi = UInt32(range.endIndex   + offset)
    
    return Int(mini + arc4random_uniform(maxi - mini)) - offset
}

let backgroundDispatchScheduler = SerialDispatchQueueScheduler(globalConcurrentQueuePriority: .High)

class GithubAPIViewController: UIViewController {

    @IBOutlet weak var refreshButton: UIButton!
    
    @IBOutlet weak var avatar1: UIImageView!
    @IBOutlet weak var label1: UILabel!
    @IBOutlet weak var close1: UIButton!
    
    
    @IBOutlet weak var avatar2: UIImageView!
    @IBOutlet weak var label2: UILabel!
    @IBOutlet weak var close2: UIButton!
    
    @IBOutlet weak var avatar3: UIImageView!
    @IBOutlet weak var label3: UILabel!
    @IBOutlet weak var close3: UIButton!
    
    private let disposeBag = DisposeBag()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        close1.transform = CGAffineTransformMakeRotation(CGFloat(45 * M_PI/180))
        close2.transform = CGAffineTransformMakeRotation(CGFloat(45 * M_PI/180))
        close3.transform = CGAffineTransformMakeRotation(CGFloat(45 * M_PI/180))
        
        viewLogic()
    }
    
    func getData(user: UserItem?) -> Observable<(label: String?, image: UIImage?)> {
        
        // If User is not set
        guard let user = user else {
            return just((nil, nil));
        }
        
        let avatarUrl = NSURL(string: user.avatar_url)!
        let req = NSURLRequest(URL: avatarUrl)
        
        return LocalURLSession.rx_data(req).map({ (user.login, UIImage(data: $0)!) })
    }
    
    
    func viewLogic() {
        
        let refresh$ = refreshButton.rx_tap.map({_ in "click"})
        let close1$ = close1.rx_tap.map({_ in "close 1"})
        let close2$ = close2.rx_tap.map({_ in "close 2"})
        let close3$ = close3.rx_tap.map({_ in "close 3"})
        
        let request$ = refresh$
            .startWith("On Load")
            .map({ _ in return random(0 ... 1000) }) // Generate Random Numbers between 0 and 1000
            .map({ NSURL(string: "https://api.github.com/users?since=\($0)")! })

        let response$ = request$
            .map({ LocalURLSession.rx_JSON($0) })
            .switchLatest()
            .map({ json -> [UserItem] in decode(json)! })
            .debug("Loading Github API Data")
            .shareReplay(1) // This shares a single subscription around. Effectively turns into a Hot Observable after the first subscriber.
        
        let createSuggestion = {(closeClick$: Observable<String>) -> Observable<UserItem?> in
            
            let fetchUser$ = combineLatest(closeClick$, response$, resultSelector: { (_, users) -> UserItem? in
                return users[random(0 ... (users.count - 1))]
            })
            
            let clearOnRefresh$ = refresh$.map({ _ -> UserItem? in return nil })
            
            return sequenceOf(clearOnRefresh$, fetchUser$).merge().shareReplay(1)
            
        }
        
        let suggestion1$ = createSuggestion(close1$.startWith("Trigger Event"))
        let suggestion2$ = createSuggestion(close2$.startWith("Trigger Event"))
        let suggestion3$ = createSuggestion(close3$.startWith("Trigger Event"))
        
        suggestion1$
        .flatMap(getData)
        .subscribeOn(backgroundDispatchScheduler)
        .observeOn(MainScheduler.sharedInstance)
        .subscribeNext({ [unowned self] (label: String?, image: UIImage?) in
            self.label1.text = label
            self.avatar1.image = image
        })
        .addDisposableTo(disposeBag)
        
        suggestion2$
        .flatMap(getData)
        .subscribeOn(backgroundDispatchScheduler)
        .observeOn(MainScheduler.sharedInstance)
        .subscribeNext({ [unowned self] (label: String?, image: UIImage?) in
            self.label2.text = label
            self.avatar2.image = image
        })
        .addDisposableTo(disposeBag)

        suggestion3$
        .flatMap(getData)
        .subscribeOn(backgroundDispatchScheduler)
        .observeOn(MainScheduler.sharedInstance)
        .subscribeNext({ [unowned self] (label: String?, image: UIImage?) in
            self.label3.text = label
            self.avatar3.image = image
        })
        .addDisposableTo(disposeBag)
        
    }
    
}




























struct UserItem {
    let avatar_url: String
    let login: String
}

extension UserItem: Decodable {
    static func decode(json: JSON) -> Decoded<UserItem> {
        return curry(UserItem.init)
        <^> json <| "avatar_url"
        <*> json <| "login"
    }
}

