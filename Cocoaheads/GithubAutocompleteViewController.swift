//
//  GithubAutocompleteViewController.swift
//  BFPG-P
//
//  Created by Harish Subramanium on 23/11/2015.
//  Copyright © 2015 private. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

import Argo
import Curry

// MARK: Return shared NSURLSession for the related Rx Methods
private var LocalURLSession: NSURLSession = {
    
    var config = NSURLSessionConfiguration.defaultSessionConfiguration()
    
    config.HTTPAdditionalHeaders = [
        "Content-Type"  : "application/json",
        "Accept"        : "application/json"
    ];
    
    // Setting a 15 second timeout for all requests
    config.timeoutIntervalForRequest = 15
    
    return NSURLSession(configuration: config)
}()

private let backgroundDispatchScheduler = SerialDispatchQueueScheduler(globalConcurrentQueuePriority: .High)
private let GithubUserSearchUrl = "https://api.github.com/search/users?q="

class GithubAutocompleteViewController: UIViewController {
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var searchTextField: UITextField!
    @IBOutlet weak var progressSpinner: UIActivityIndicatorView!
    
    private let disposeBag = DisposeBag()
    private var dataSet: [UserItem] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.tableView.dataSource = self

        progressSpinner.hidesWhenStopped = true
        progressSpinner.activityIndicatorViewStyle = .Gray
        
        viewLogic()
    }
    
    override func viewWillDisappear(animated: Bool) {
        self.tableView.dataSource = nil
    }
    
    func viewLogic() {
        
        let searchText$ = searchTextField.rx_text
        
        let request$ = searchText$
            .filter({ $0.characters.count > 0 })
            .map({ NSURL(string: "\(GithubUserSearchUrl)\($0)")! })
            .map({ LocalURLSession.rx_JSON($0) })
            .shareReplay(1)
        
        let response$ = request$
            .switchLatest()
            .map({ json -> GithubUserResponse? in
                let res: GithubUserResponse? = decode(json)
                return res
            })
            .shareReplay(1)
        
        sequenceOf(request$.map {_ in true }, response$.map {_ in false })
            .merge()
            .subscribeOn(backgroundDispatchScheduler)
            .observeOn(MainScheduler.sharedInstance)
            .subscribeNext({ [unowned self] bool in
                if bool {
                    self.progressSpinner.startAnimating()
                } else {
                    self.progressSpinner.stopAnimating()
                }
            })
            .addDisposableTo(disposeBag)

        
        response$
            .subscribeOn(backgroundDispatchScheduler)
            .observeOn(MainScheduler.sharedInstance)
            .subscribeNext({ [unowned self] in
                
                guard let githubResponse = $0 else {
                    self.dataSet = []
                    self.tableView.reloadData()
                    return
                }
                
                let userItems = githubResponse.items
                let minCount = min(100, userItems.count)
                let slicedDataSet: [UserItem] = Array(userItems[0 ..< minCount])
                
                self.dataSet = slicedDataSet
                self.tableView.reloadData()
            })
            .addDisposableTo(disposeBag)
        
    }
    
}

// TableView Datasource methods
let cellId = "GithubUserCellID"
extension GithubAutocompleteViewController: UITableViewDataSource {
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return dataSet.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {

        let row = indexPath.row
        
        let cell = tableView.dequeueReusableCellWithIdentifier(cellId, forIndexPath: indexPath) as! GithubUserCell
        cell.configureForUserItem(dataSet[row])
        
        return cell
    }
    
}

// Cell for the TableView
private func getAvatarImage(url: String) -> Observable<UIImage?> {
    
    let avatarUrl = NSURL(string: url)!
    let req = NSURLRequest(URL: avatarUrl)
    
    return LocalURLSession.rx_data(req).map({ UIImage(data: $0) })
}


class GithubUserCell: UITableViewCell {
    
    @IBOutlet weak var userAvatar: UIImageView!
    @IBOutlet weak var userLogin: UILabel!
    @IBOutlet weak var userScore: UILabel!
    
    private let disposeBag = DisposeBag()
    
    private func configureForUserItem(user: UserItem) {
        
        self.userLogin.text = user.login
        self.userScore.text = "\(user.score)"
        self.userAvatar.image = nil
        
        getAvatarImage(user.avatar_url)
        .take(1)
        .subscribeOn(backgroundDispatchScheduler)
        .observeOn(MainScheduler.sharedInstance)
        .subscribeNext { [unowned self] image -> Void in
            
            guard let validImage = image else {
                return
            }
            
            self.userAvatar.image = validImage
        }
        .addDisposableTo(disposeBag)
    }
    
}

private struct GithubUserResponse {
    let total_count: Int
    let items: [UserItem]
}

extension GithubUserResponse: Decodable {

    static func decode(json: JSON) -> Decoded<GithubUserResponse> {
        
        return curry(GithubUserResponse.init)
            <^> json <| "total_count"
            <*> json <|| "items"
    }
}

private struct UserItem {
    let avatar_url: String
    let login: String
    let score: Float
}

extension UserItem: Decodable {
    static func decode(json: JSON) -> Decoded<UserItem> {
        return curry(UserItem.init)
            <^> json <| "avatar_url"
            <*> json <| "login"
            <*> json <| "score"
    }
}

