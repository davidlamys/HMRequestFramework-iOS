//
//  CoreDataManagerTest.swift
//  HMRequestFrameworkTests
//
//  Created by Hai Pham on 21/7/17.
//  Copyright © 2017 Holmusk. All rights reserved.
//

import CoreData
import RxSwift
import RxBlocking
import RxTest
import SwiftUtilities
import SwiftUtilitiesTests
import XCTest
@testable import HMRequestFramework

public class CoreDataManagerTest: XCTestCase {
    public typealias Req = HMCDRequestProcessor.Req
    let timeout: TimeInterval = 1000
    let iterationCount = 100
    let dummyCount = 100
    let dummyTypeCount = 2
    let dummy: Try<Any> = Try.success(1)
    var manager: HMCDManager!
    var disposeBag: DisposeBag!
    var scheduler: TestScheduler!
    
    override public func setUp() {
        super.setUp()
        manager = Singleton.dummyCDManager()
        disposeBag = DisposeBag()
        scheduler = TestScheduler(initialClock: 0)
    }
    
    public func test_constructBuildable_shouldWork() {
        /// Setup
        let observer = scheduler.createObserver(Dummy2.self)
        let expect = expectation(description: "Should have completed")
        let manager = self.manager!
        let context = manager.disposableObjectContext()
        let dummies = (0..<10000).map({_ in Dummy2()})
        
        /// When
        manager.rx.construct(context, dummies)
            .flatMap({Observable.from($0)})
            .map({$0.asPureObject()})
            .doOnDispose(expect.fulfill)
            .subscribe(observer)
            .disposed(by: disposeBag)
        
        waitForExpectations(timeout: timeout, handler: nil)
            
        /// Then
        let nextElements = observer.nextElements()
        XCTAssertEqual(dummies, nextElements)
    }
    
    public func test_saveAndFetchBuildable_shouldWork() {
        /// Setup
        let observer = scheduler.createObserver(CDDummy2.self)
        let expect = expectation(description: ("Should have completed"))
        let dummyCount = self.dummyCount
        let manager = self.manager!
        let mainContext = manager.mainContext
        let privateContext = manager.privateContext
        let dummies = (0..<dummyCount).map({_ in Dummy2()})
        let fetchRq: NSFetchRequest<CDDummy2> = try! dummy2FetchRequest().fetchRequest()
        XCTAssertTrue(mainContext.insertedObjects.isEmpty)
        XCTAssertTrue(privateContext.insertedObjects.isEmpty)
        
        /// When
        // Save the dummies in memory. Their NSManagedObject equivalents will
        // be constructed here.
        manager.rx.save(dummies)
            
            // Perform a fetch to verify that the data have been inserted, but
            // not persisted.
            .flatMap({manager.rx.fetch(fetchRq)})
            .doOnNext({XCTAssertEqual($0.count, dummyCount)})
            .doOnNext({_ in XCTAssertEqual(mainContext.insertedObjects.count, dummyCount)})
            .doOnNext({_ in XCTAssertTrue(privateContext.insertedObjects.isEmpty)})
            .map(toVoid)
            
            // Persist the data.
            .flatMap(manager.rx.persistLocally)
            
            // Fetch the data and verify that they have been persisted.
            .flatMap({manager.rx.fetch(fetchRq)})
            .flatMap({Observable.from($0)})
            .doOnDispose(expect.fulfill)
            .subscribe(observer)
            .disposed(by: disposeBag)
        
        waitForExpectations(timeout: timeout, handler: nil)
        
        /// Then
        let nextElements = observer.nextElements()
        XCTAssertEqual(nextElements.count, dummyCount)
    }
    
    public func test_refetchUpsertables_shouldWork() {
        /// Setup
        let observer = scheduler.createObserver(Dummy1.CDClass.self)
        let expect = expectation(description: "Should have completed")
        let manager = self.manager!
        let context = manager.disposableObjectContext()
        let dummyCount = self.dummyCount
        let data = (0..<dummyCount).flatMap({_ in try! Dummy1.CDClass(context)})
        
        let fetchRq = try! HMCDRequest.builder()
            .with(poType: Dummy1.self)
            .with(operation: .fetch)
            .with(predicate: manager.predicateForUpsertableFetch(data))
            .build()
            .fetchRequest(Dummy1.CDClass.self)
        
        let entityName = fetchRq.entityName!
        
        /// When
        // Save data without persisting to DB.
        manager.rx.save(context)
            
            // Persist data to DB.
            .flatMap(manager.rx.persistLocally)
            
            // Refetch based on identifiable objects. We expect the returned
            // data to contain the same properties.
            .flatMap({manager.rx.refetch(entityName, data)})
            .doOnNext({XCTAssertEqual($0.count, dummyCount)})
            .flatMap({Observable.from($0)})
            .doOnDispose(expect.fulfill)
            .subscribe(observer)
            .disposed(by: disposeBag)
        
        waitForExpectations(timeout: timeout, handler: nil)
        
        /// Then
        let nextElements = observer.nextElements()
        
        XCTAssertTrue(nextElements.all(satisfying: {dummy in
            data.contains(where: {$0.id == dummy.id})
        }))
    }
    
    public func test_insertAndDeleteUpsertables_shouldWork() {
        /// Setup
        let observer = scheduler.createObserver(Dummy1.CDClass.self)
        let expect = expectation(description: "Should have completed")
        let manager = self.manager!
        
        // Two contexts for two operations, no shared context.
        let context1 = manager.disposableObjectContext()
        let context2 = manager.disposableObjectContext()
        let dummyCount = self.dummyCount
        let data1 = (0..<dummyCount).flatMap({_ in try? Dummy1.CDClass.init(context1)})
        
        let data2 = (0..<dummyCount).flatMap({(i) -> Dummy1.CDClass? in
            let dummy = try? Dummy1.CDClass.init(context2)
            dummy?.id = data1[i].id
            return dummy
        })
        
        let fetchRq = try! HMCDRequest.builder()
            .with(poType: Dummy1.self)
            .with(operation: .fetch)
            .with(predicate: NSPredicate(value: true))
            .build()
            .fetchRequest(Dummy1.CDClass.self)
        
        let entityName = fetchRq.entityName!
        
        /// When
        // Save data1 to memory without persisting to DB.
        manager.rx.save(context1)
            
            // Persist changes to DB. At this stage, data1 is the only set
            // of data within the DB.
            .flatMap(manager.rx.persistLocally)
            
            // Fetch to verify that the DB only contains data1.
            .flatMap({manager.rx.fetch(fetchRq)})
            .doOnNext({XCTAssertEqual($0.count, dummyCount)})
            
            // Delete data2 from memory. data1 and data2 are two different
            // sets of data that only have the same primary key-value.
            .flatMap({_ in manager.rx.delete(entityName, data2)})
            
            // Persist changes to DB.
            .flatMap(manager.rx.persistLocally)
            
            // Fetch to verify that the DB is now empty.
            .flatMap({manager.rx.fetch(fetchRq)})
            .flatMap({Observable.from($0)})
            .doOnDispose(expect.fulfill)
            .subscribe(observer)
            .disposed(by: disposeBag)
        
        waitForExpectations(timeout: timeout, handler: nil)
        
        /// Then
        let nextElements = observer.nextElements()
        XCTAssertEqual(nextElements.count, 0)
    }
    
    public func test_insertAndDeleteManyRandomDummies_shouldWork() {
        /// Setup
        let observer = scheduler.createObserver(Dummy1.CDClass.self)
        let expect = expectation(description: "Should have completed")
        let manager = self.manager!
        let iterationCount = self.iterationCount
        let dummyCount = self.dummyCount
        let request = try! dummy1FetchRequest().fetchRequest(Dummy1.CDClass.self)
        let entityName = request.entityName!
        
        /// When
        Observable.from(0..<iterationCount)
            
            // For each iteration, create a bunch of dummies in a disposable
            // context and save them in memory. The main context should then
            // own the changes.
            .flatMap({(i) -> Observable<Void> in
                print("Creating dummies, iteration \(i)")
                let context = manager.defaultCreateContext()
                
                return Observable<Void>
                    .create({
                        _ = (0..<dummyCount).map({_ in try! Dummy1.CDClass.init(context)})
                        $0.onNext(())
                        $0.onCompleted()
                        return Disposables.create()
                    })
                    .flatMap({manager.rx.save(context)})
                    .subscribeOn(qos: .background)
            })
            .reduce((), accumulator: {_ in ()})
            
            // Persist all changes to DB.
            .flatMap(manager.rx.persistLocally)
            
            // Fetch to verify that the data have been persisted.
            .flatMap({manager.rx.fetch(request)})
            .doOnNext({XCTAssertEqual($0.count, iterationCount * dummyCount)})
            .map({$0.map({$0.asPureObject()})})
            .flatMap({manager.rx.construct(manager.defaultDeleteContext(), $0)})
            
            // Delete from memory, but do not persist yet.
            .flatMap({manager.rx.delete(entityName, $0)})
            
            // Persist the changes.
            .flatMap(manager.rx.persistLocally)
            
            // Fetch to verify that the data have been deleted.
            .flatMap({manager.rx.fetch(request).subscribeOn(qos: .background)})
            .flatMap({Observable.from($0)})
            .doOnDispose(expect.fulfill)
            .subscribe(observer)
            .disposed(by: disposeBag)
        
        waitForExpectations(timeout: timeout, handler: nil)
        
        /// Then
        let elements = observer.nextElements()
        XCTAssertEqual(elements.count, 0)
    }
    
    public func test_predicateForUpsertFetch_shouldWork() {
        /// Setup
        let times = 1000
        let context = manager.defaultCreateContext()
        let pureObjs = (0..<times).map({_ in Dummy1()})
        let objs = try! manager.constructUnsafely(context, pureObjs)
        
        /// When
        let predicate = manager.predicateForUpsertableFetch(objs)
        
        /// Then
        let description = predicate.description
        let dComponents = description.components(separatedBy: " ")
        let dummyValues = objs.map({$0.primaryValue()})
        XCTAssertEqual(dComponents.filter({$0 == "OR"}).count, times - 1)
        XCTAssertTrue(dummyValues.all(satisfying: description.contains))
    }
}

extension CoreDataManagerTest {
    func dummy1FetchRequest() -> Req {
        return Req.builder()
            .with(poType: Dummy1.self)
            .with(operation: .fetch)
            .with(predicate: NSPredicate(value: true))
            .with(sortDescriptors: NSSortDescriptor(key: "id", ascending: true))
            .build()
    }
}

extension CoreDataManagerTest {
    func dummy2FetchRequest() -> Req {
        return Req.builder()
            .with(cdType: CDDummy2.self)
            .with(operation: .fetch)
            .with(predicate: NSPredicate(value: true))
            .with(sortDescriptors: NSSortDescriptor(key: "id", ascending: true))
            .build()
    }
}
