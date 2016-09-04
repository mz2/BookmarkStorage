//
//  URLAccess.swift
//  BookmarkStorage
//
//  Created by Matias Piipari on 04/09/2016.
//  Copyright © 2016 Matias Piipari & Co. All rights reserved.
//

import Foundation

public struct URLAccessOptions:OptionSet {
    public let rawValue: Int
    
    public init(rawValue: Int) {
        self.rawValue = rawValue
    }
    
    public static let groupAccessByParentDirectoryURL = URLAccessOptions(rawValue:1 << 0)
    public static let alwaysAskForAccessToParentDirectory = URLAccessOptions(rawValue: 1 << 1)
};

/** Return nil if access was what you would define as success, error otherwise. */
public typealias URLAccessHandler = (URLAccess) -> Error?

public protocol URLAccess {
    /** Return all URLs that will require security-scoped access. */
    var URLs:[URL] { get }
}

public struct SimpleURLAccess : URLAccess {
    public let URLs:[URL]
    
    public init(URLs:[URL]) {
        self.URLs = URLs
    }
}

public enum SecurityScopeAccessOutcome {
    case success(bookmarkData:Data)
    case cancelled
    case failure
}
    
