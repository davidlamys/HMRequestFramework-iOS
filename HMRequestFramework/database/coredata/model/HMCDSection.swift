//
//  HMCDSection.swift
//  HMRequestFramework
//
//  Created by Hai Pham on 8/26/17.
//  Copyright © 2017 Holmusk. All rights reserved.
//

import CoreData
import SwiftUtilities

/// Use this struct instead of NSFetchedResultSectionInfo.
public struct HMCDSection<V>: HMCDSectionType {
    public let indexTitle: String?
    public let name: String
    public let numberOfObjects: Int
    public let objects: [V]
    
    public init<S>(indexTitle: String?,
                   name: String,
                   numberOfObjects: Int,
                   objects: S) where
        S: Sequence, S.Iterator.Element == V
    {
        self.indexTitle = indexTitle
        self.name = name
        self.numberOfObjects = numberOfObjects
        self.objects = objects.map({$0})
    }
    
    /// Map the current section info to a different generic.
    ///
    /// - Parameter f: Transform function.
    /// - Returns: A HMCDSection instance.
    public func map<V2>(_ f: (V) throws -> V2) -> HMCDSection<V2> {
        return HMCDSection<V2>(indexTitle: self.indexTitle,
                               name: self.name,
                               numberOfObjects: self.numberOfObjects,
                               objects: self.objects.flatMap({try? f($0)}))
    }
    
    /// Convenience function to cast the current generic to some other type.
    ///
    /// - Parameter cls: The V2 class type.
    /// - Returns: A HMCDSection instance.
    public func cast<V2>(to cls: V2.Type) -> HMCDSection<V2> {
        return map({
            if let v2 = $0 as? V2 {
                return v2
            } else {
                throw Exception("Unable to cast \($0) to \(cls)")
            }
        })
    }
}

public extension HMCDSection where V == Any {
    public init(_ sectionInfo: NSFetchedResultsSectionInfo) {
        self.init(
            indexTitle: sectionInfo.indexTitle,
            name: sectionInfo.name,
            numberOfObjects: sectionInfo.numberOfObjects,
            objects: sectionInfo.objects ?? []
        )
    }
}

public extension HMCDSection where
    V: HMCDPureObjectType,
    V.CDClass: HMCDPureObjectConvertibleType,
    V.CDClass.PureObject == V
{
    public init(_ sectionInfo: NSFetchedResultsSectionInfo) {
        self.init(
            indexTitle: sectionInfo.indexTitle,
            name: sectionInfo.name,
            numberOfObjects: sectionInfo.numberOfObjects,
            objects: sectionInfo.objects?
                .flatMap({$0 as? V.CDClass})
                .map({$0.asPureObject()}) ?? [V]()
        )
    }
}
