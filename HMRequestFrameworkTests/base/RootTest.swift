//
//  RootTest.swift
//  HMRequestFrameworkTests
//
//  Created by Hai Pham on 25/8/17.
//  Copyright © 2017 Holmusk. All rights reserved.
//

import RxTest
import RxSwift
import SwiftUtilities
import XCTest

public class RootTest: XCTestCase {
    var dummy: Try<Any>!
    var timeout: TimeInterval!
    var scheduler: TestScheduler!
    var disposeBag: DisposeBag!
    
    override public func setUp() {
        super.setUp()
        disposeBag = DisposeBag()
        scheduler = TestScheduler(initialClock: 0)
        timeout = 1000
        dummy = Try.success(())
    }
    
    override public func tearDown() {
        super.tearDown()
        disposeBag = nil
    }
}
