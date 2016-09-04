//
//  UserDefaultsStor.swift
//  BookmarkStorage
//
//  Created by Matias Piipari on 04/09/2016.
//  Copyright © 2016 Matias Piipari & Co. All rights reserved.
//

import Foundation

public struct UserDefaultsBookmarkStorageDelegate:BookmarkStorageDelegate {
    
    public static let UserDefaultsKey:String = "UserDefaultsBookmarkStoreAllBookmarks"
    
    public func allBookmarkDataByAbsoluteURLString() throws -> [String:Data] {
        guard let d = UserDefaults.standard.object(forKey: type(of: self).UserDefaultsKey) as? [String:Data] else {
            throw BookmarkStorageError.noBookmarkDataWhatsoeverStored
        }
        return d
    }
    
    public func bookmarkData(forURL URL:URL) throws -> Data {
        guard let data = try self.allBookmarkDataByAbsoluteURLString()[URL.absoluteString] else {
            throw BookmarkStorageError.noBookmarkDataStored(URL)
        }
        
        return data
    }
    
    public func saveBookmark(data: Data, forURL URL: URL) throws {
        
        let allBookmarks = { () -> [String : Data] in
            do {
                var existingBookmarks = try self.allBookmarkDataByAbsoluteURLString()
                existingBookmarks[URL.absoluteString] = data
                return existingBookmarks
            } catch {
                return [URL.absoluteString: data]
            }
        }()
        
        let defs = UserDefaults.standard
        defs.set(allBookmarks, forKey: type(of: self).UserDefaultsKey)
        if !defs.synchronize() {
            throw BookmarkStorageError.failedToSave(reason: "Synchronizing user defaults failed.")
        }
    }
}
