//
//  HMCDGeneralRequestProcessorType.swift
//  HMRequestFramework
//
//  Created by Hai Pham on 21/8/17.
//  Copyright © 2017 Holmusk. All rights reserved.
//

import RxSwift
import SwiftUtilities

/// Classes that implement this protocol must be able to handle common CoreData
/// requests.
public protocol HMCDGeneralRequestProcessorType {
    
    /// Fetch all data of a type from DB, then convert them to pure objects.
    ///
    /// - Parameters:
    ///   - previous: The result of the previous request.
    ///   - cls: The PureObject class type.
    ///   - transforms: A Sequence of Request transformer.
    /// - Returns: An Observable instance.
    func fetchAllDataFromDB<Prev,PO,S>(_ previous: Try<Prev>,
                                       _ cls: PO.Type,
                                       _ transforms: S)
        -> Observable<Try<[PO]>> where
        PO: HMCDPureObjectType,
        PO.CDClass: HMCDPureObjectConvertibleType,
        PO.CDClass.PureObject == PO,
        S: Sequence,
        S.Iterator.Element == HMTransform<HMCDRequest>
    
    /// Save some data to memory by constructing them and then saving the
    /// resulting managed objects.
    ///
    /// - Parameters:
    ///   - previous: The result of the previous operation.
    ///   - transforms: A Sequence of Request transformer.
    /// - Returns: An Observable instance.
    func saveToMemory<PO,S>(_ previous: Try<[PO]>, _ transforms: S)
        -> Observable<Try<Void>> where
        PO: HMCDPureObjectType,
        PO.CDClass: HMCDObjectConvertibleType,
        PO.CDClass: HMCDObjectBuildableType,
        PO.CDClass.Builder.PureObject == PO,
        S: Sequence,
        S.Iterator.Element == HMTransform<HMCDRequest>
    
    /// Delete some data in memory.
    ///
    /// - Parameters:
    ///   - previous: The result of the previous operation.
    ///   - transforms: A Sequence of Request transformers.
    /// - Returns: An Observable instance.
    func deleteInMemory<PO,S>(_ previous: Try<[PO]>, _ transforms: S)
        -> Observable<Try<Void>> where
        PO: HMCDPureObjectType,
        PO: HMCDObjectConvertibleType,
        S: Sequence,
        S.Iterator.Element == HMTransform<HMCDRequest>
    
    /// Delete all data of some type in memory.
    ///
    /// - Parameters:
    ///   - previous: The result of the previous operation.
    ///   - cls: A PO class type.
    ///   - transforms: A Sequence of Request transformers.
    /// - Returns: An Observable instance.
    func deleteAllInMemory<Prev,PO,S>(_ previous: Try<Prev>,
                                      _ cls: PO.Type,
                                      _ transforms: S)
        -> Observable<Try<Void>> where
        PO: HMCDPureObjectType,
        PO.CDClass: HMCDPureObjectConvertibleType,
        PO.CDClass.PureObject == PO,
        S: Sequence,
        S.Iterator.Element == HMTransform<HMCDRequest>
    
    /// Reset the CoreData stack and wipe DB.
    ///
    /// - Parameters:
    ///   - previous: The result of the previous operation.
    ///   - transforms: A Sequence of Request transformers.
    /// - Returns: An Observable instance.
    func resetStack<Prev,S>(_ previous: Try<Prev>, _ transforms: S)
        -> Observable<Try<Void>> where
        S: Sequence, S.Iterator.Element == HMTransform<HMCDRequest>
    
    /// Perform an upsert operation with some upsertable data.
    ///
    /// - Parameters:
    ///   - previous: The result of the previous request.
    ///   - transforms: A Sequence of Request transformers.
    /// - Returns: An Observable instance.
    func upsertInMemory<U,S>(_ previous: Try<[U]>, _ transforms: S)
        -> Observable<Try<[HMCDResult]>> where
        U: HMCDObjectType,
        U: HMCDUpsertableType,
        S: Sequence,
        S.Iterator.Element == HMTransform<HMCDRequest>
    
    /// Perform an upsert operation with some pure objects by constructing
    /// managed objects and then upserting them afterwards.
    ///
    /// - Parameters:
    ///   - previous: The result of the previous request.
    ///   - transforms: A Sequence of Request transformers.
    /// - Returns: An Observable instance.
    func upsertInMemory<PO,S>(_ previous: Try<[PO]>, _ transform: S)
        -> Observable<Try<[HMCDResult]>> where
        PO: HMCDPureObjectType,
        PO.CDClass: HMCDUpsertableType,
        PO.CDClass: HMCDObjectBuildableType,
        PO.CDClass.Builder.PureObject == PO,
        S: Sequence,
        S.Iterator.Element == HMTransform<HMCDRequest>
    
    /// Persist all data to DB.
    ///
    /// - Parameters:
    ///   - previous: The result of the previous request.
    ///   - transform: A Sequence of Request transformers.
    /// - Returns: An Observable instance.
    func persistToDB<Prev,S>(_ previous: Try<Prev>, _ transform: S)
        -> Observable<Try<Void>> where
        S: Sequence, S.Iterator.Element == HMTransform<HMCDRequest>
    
    /// Stream DB changes for some pure object type.
    ///
    /// - Parameters:
    ///   - cls: The PO class type.
    ///   - transforms: A Sequence of Request transformers.
    /// - Returns: An Observable instance.
    func streamDBEvents<S,PO>(_ cls: PO.Type, _ transforms: S)
        -> Observable<Try<HMCDEvent<PO>>> where
        PO: HMCDPureObjectType,
        PO.CDClass: HMCDPureObjectConvertibleType,
        PO.CDClass.PureObject == PO,
        S: Sequence,
        S.Iterator.Element == HMTransform<HMCDRequest>
}

public extension HMCDGeneralRequestProcessorType {
    
    /// Fetch all data that have some properties. These properties will be
    /// mapped into a series of predicates and joined together with AND.
    ///
    /// - Parameters:
    ///   - previous: The result of the previous request.
    ///   - cls: The PO class type.
    ///   - transforms: A Sequence of Request transformers.
    /// - Returns: An Observable instance.
    public func fetchWithProperties<PO,S>(_ previous: Try<[String : [CVarArg]]>,
                                          _ cls: PO.Type,
                                          _ transforms: S)
        -> Observable<Try<[PO]>> where
        PO: HMCDPureObjectType,
        PO.CDClass: HMCDPureObjectConvertibleType,
        PO.CDClass.PureObject == PO,
        S: Sequence,
        S.Iterator.Element == HMTransform<HMCDRequest>
    {
        do {
            let properties = try previous.getOrThrow()
            
            let predicate = NSCompoundPredicate(andPredicateWithSubpredicates:
                properties.map({NSPredicate(format: "%K in %@", $0.0, $0.1)})
            )
            
            let propTransform: HMTransform<HMCDRequest> = {
                return Observable.just($0.cloneBuilder()
                    .with(predicate: predicate)
                    .with(requestDescription: "Fetching \(cls) with \(properties)")
                    .build())
            }
            
            let allTransforms = [propTransform] + transforms
            return fetchAllDataFromDB(Try.success(()), cls, allTransforms)
        } catch let e {
            return Observable.just(Try.failure(e))
        }
    }
}

/// Convenience method for varargs.
public extension HMCDGeneralRequestProcessorType {
    public func fetchAllDataFromDB<Prev,PO>(_ previous: Try<Prev>,
                                            _ cls: PO.Type,
                                            _ transforms: HMTransform<HMCDRequest>...)
        -> Observable<Try<[PO]>> where
        PO: HMCDPureObjectType,
        PO.CDClass: HMCDPureObjectConvertibleType,
        PO.CDClass.PureObject == PO
    {
        return fetchAllDataFromDB(previous, cls, transforms)
    }
    
    public func fetchWithProperties<PO>(_ previous: Try<[String : [CVarArg]]>,
                                        _ cls: PO.Type,
                                        _ transforms: HMTransform<HMCDRequest>...)
        -> Observable<Try<[PO]>> where
        PO: HMCDPureObjectType,
        PO.CDClass: HMCDPureObjectConvertibleType,
        PO.CDClass.PureObject == PO
    {
        return fetchWithProperties(previous, cls, transforms)
    }
    
    public func saveToMemory<PO>(_ previous: Try<[PO]>,
                                 _ transforms: HMTransform<HMCDRequest>...)
        -> Observable<Try<Void>> where
        PO: HMCDPureObjectType,
        PO.CDClass: HMCDObjectConvertibleType,
        PO.CDClass: HMCDObjectBuildableType,
        PO.CDClass.Builder.PureObject == PO
    {
        return saveToMemory(previous, transforms)
    }
    
    public func deleteInMemory<PO>(_ previous: Try<[PO]>,
                                   _ transforms: HMTransform<HMCDRequest>...)
        -> Observable<Try<Void>> where
        PO: HMCDPureObjectType,
        PO: HMCDObjectConvertibleType
    {
        return deleteInMemory(previous, transforms)
    }
    
    public func deleteAllInMemory<Prev,PO>(_ previous: Try<Prev>,
                                           _ cls: PO.Type,
                                           _ transforms: HMTransform<HMCDRequest>...)
        -> Observable<Try<Void>> where
        PO: HMCDPureObjectType,
        PO.CDClass: HMCDPureObjectConvertibleType,
        PO.CDClass.PureObject == PO
    {
        return deleteAllInMemory(previous, cls, transforms)
    }
    
    public func resetStack<Prev>(_ previous: Try<Prev>,
                                 _ transforms: HMTransform<HMCDRequest>...)
        -> Observable<Try<Void>>
    {
        return resetStack(previous, transforms)
    }
    
    public func upsertInMemory<U>(_ previous: Try<[U]>,
                                  _ transforms: HMTransform<HMCDRequest>...)
        -> Observable<Try<[HMCDResult]>> where
        U: HMCDObjectType, U: HMCDUpsertableType
    {
        return upsertInMemory(previous, transforms)
    }
    
    public func upsertInMemory<PO>(_ previous: Try<[PO]>,
                                   _ transforms: HMTransform<HMCDRequest>...)
        -> Observable<Try<[HMCDResult]>> where
        PO: HMCDPureObjectType,
        PO.CDClass: HMCDUpsertableType,
        PO.CDClass: HMCDObjectBuildableType,
        PO.CDClass.Builder.PureObject == PO
    {
        return upsertInMemory(previous, transforms)
    }
    
    public func persistToDB<Prev>(_ previous: Try<Prev>,
                                  _ transforms: HMTransform<HMCDRequest>...)
        -> Observable<Try<Void>>
    {
        return persistToDB(previous, transforms)
    }
    
    public func streamDBEvents<PO>(_ cls: PO.Type,
                                    _ transforms: HMTransform<HMCDRequest>...)
        -> Observable<Try<HMCDEvent<PO>>> where
        PO: HMCDPureObjectType,
        PO.CDClass: HMCDPureObjectConvertibleType,
        PO.CDClass.PureObject == PO
    {
        return streamDBEvents(cls, transforms)
    }
}
