//: Playground - noun: a place where people can play

import UIKit
import RxSwift
import RxCocoa

let a = BehaviorSubject(value: 1) // [1]
let b = BehaviorSubject(value: 2) // [2]

//a.subscribeNext { print($0) }

//a.onNext(3) // [1, 3]
//a.onNext(5) // [1, 3, 5]
//a.onNext(7) // [1, 3, 5, 7]

//b.onNext(4) // [2, 4]
//b.onNext(6) // [2, 4, 6]
//b.onNext(8) // [2, 4, 6, 8]

a.filter({ $0 == 3 })
    .subscribeNext({ print("filter --> \($0)") })

combineLatest(a, b) { $0 * $1 }
    .subscribeNext({ print("\t\t\tcombine Latest --> \($0)") })

zip(a, b) { $0 + $1 }
    .subscribeNext({ print("\t\t\t\t\t\t\t\tzip --> \($0)") })