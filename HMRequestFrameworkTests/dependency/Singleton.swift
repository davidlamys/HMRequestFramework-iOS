//
//  Singleton.swift
//  HMRequestFramework
//
//  Created by Hai Pham on 7/25/17.
//  Copyright © 2017 Holmusk. All rights reserved.
//

@testable import HMRequestFramework

public final class Singleton {
    public static func cdManager() -> HMCDManager {
        return dummyCDManager()
    }
    
    public static func dummyCDSettings() -> [HMPersistentStoreSettings] {
        return [
            HMPersistentStoreSettings.builder().with(storeType: .InMemory).build()
        ]
    }
    
    public static func dummyCDConstructor() -> HMCDConstructor {
        return HMCDConstructor.builder()
            .with(cdTypes: Dummy1.CDClass.self, Dummy2.CDClass.self)
            .with(settings: dummyCDSettings())
            .build()
    }
    
    public static func dummyCDManager() -> HMCDManager {
        return try! HMCDManager(constructor: dummyCDConstructor())
    }
    
    private init() {}
}
