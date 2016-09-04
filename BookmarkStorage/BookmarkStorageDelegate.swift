//
//  BookmarkStorageDelegate.swift
//  BookmarkStorage
//
//  Created by Matias Piipari on 04/09/2016.
//  Copyright © 2016 Matias Piipari & Co. All rights reserved.
//

import Foundation

public protocol BookmarkStorageDelegate {
    
    /** Retrieve all bookmark data objects stored by this delegate, with absolute string representations of URLs as keys, and NSData objects as values. */
    
    func allBookmarkDataByAbsoluteURLString() throws -> [String:Data]
    
    /** Retrieve bookmark data previously stored for a URL. */
    func bookmarkData(forURL:URL) throws -> Data
    
    /** Store bookmark data for given URL. If bookmark data is already stored for the given URL, replace it. */
    func saveBookmark(data:Data, forURL:URL) throws
}
