//
//  MockRequest.swift
//  HMRequestFrameworkTests
//
//  Created by Hai Pham on 7/29/17.
//  Copyright © 2017 Holmusk. All rights reserved.
//

@testable import HMRequestFramework

public struct MockRequest {
    fileprivate var mFilters: [MiddlewareFilter]
    fileprivate var retryCount: Int
    fileprivate var middlewaresEnabled: Bool
    fileprivate var rqDescription: String?
    
    fileprivate init() {
        mFilters = []
        retryCount = 1
        middlewaresEnabled = false
    }
}

extension MockRequest: HMRequestType {
    public typealias Filterable = String
    
    public func middlewareFilters() -> [MiddlewareFilter] {
        return mFilters
    }
    
    public func retries() -> Int {
        return retryCount
    }
    
    public func applyMiddlewares() -> Bool {
        return middlewaresEnabled
    }
    
    public func requestDescription() -> String? {
        return rqDescription
    }
}

public extension MockRequest {
    public static func builder() -> Builder {
        return Builder()
    }
    
    public final class Builder: HMRequestBuilderType {
        public typealias Buildable = MockRequest
        
        fileprivate var request: Buildable
        
        init() {
            request = MockRequest()
        }
        
        @discardableResult
        public func with<S>(mwFilters: S) -> Self where
            S: Sequence, S.Iterator.Element == MiddlewareFilter
        {
            request.mFilters = mwFilters.map({$0})
            return self
        }
        
        @discardableResult
        public func add(mwFilter: MiddlewareFilter) -> MockRequest.Builder {
            request.mFilters.append(mwFilter)
            return self
        }
        
        @discardableResult
        public func with(retries: Int) -> Self {
            request.retryCount = retries
            return self
        }
        
        @discardableResult
        public func with(applyMiddlewares: Bool) -> Self {
            request.middlewaresEnabled = applyMiddlewares
            return self
        }
        
        @discardableResult
        public func with(requestDescription: String?) -> Self {
            request.rqDescription = requestDescription
            return self
        }
        
        public func with(buildable: Buildable) -> Self {
            return self
                .with(mwFilters: buildable.middlewareFilters())
                .with(applyMiddlewares: buildable.applyMiddlewares())
                .with(retries: buildable.retries())
                .with(requestDescription: buildable.requestDescription())
        }
        
        public func build() -> Buildable {
            return request
        }
    }
}
