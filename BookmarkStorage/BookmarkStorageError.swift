//
//  BookmarkStorageError.swift
//  BookmarkStorage
//
//  Created by Matias Piipari on 04/09/2016.
//  Copyright © 2016 Matias Piipari & Co. All rights reserved.
//

import Foundation

public enum BookmarkStorageError: Swift.Error {
    case noBookmarkDataWhatsoeverStored
    case noBookmarkDataStored(URL)
    case failedToSave(reason:String)
    case fileURLHasNoSystemFileNumber(URL)
    case noAccessOrFileDoesNotExist(URL)
    case userCancelled
}
