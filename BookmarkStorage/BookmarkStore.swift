//
//  BookmarkStore.swift
//  BookmarkStorage
//
//  Created by Matias Piipari on 04/09/2016.
//  Copyright © 2016 Matias Piipari & Co. All rights reserved.
//

import Cocoa


public struct BookmarkStore {

    /** Return default bookmark store instance that uses user defaults for bookmark storage. */
    static let defaultStore:BookmarkStore = BookmarkStore(delegate:UserDefaultsBookmarkStorageDelegate())
    
    private(set) public var delegate:BookmarkStorageDelegate
	
	
	public init(delegate: BookmarkStorageDelegate) {
		self.delegate = delegate
	}
    
    /** Return dictionary with parent URL absolute strings as keys, and arrays of URLs as values. */
    private static func URLsGroupedByAbsoluteParentURLStrings(URLs:[URL]) -> [String:[URL]] {
        
        var groupedURLs = [String:[URL]]()
        
        for URL in URLs {
            var parentURL = URL
            parentURL.deleteLastPathComponent()
            let parentURLString = parentURL.absoluteString
            let siblingURLs = { () -> [URL] in
                if let existingValue = groupedURLs[parentURLString] {
                    return existingValue + [URL]
                }
                
                return [URL]
            }()
            
            groupedURLs[parentURLString] = siblingURLs
        }
        
        return groupedURLs
    }
    
    private static var knownAccessibleDirectoryURLs:[URL] = {
        do {
            let applicationSupportURL = try FileManager.default.url(for: .applicationSupportDirectory,
                                                                    in: .userDomainMask,
                                                                    appropriateFor: nil,
                                                                    create: true)
            
            let cachesURL = try FileManager.default.url(for: .cachesDirectory,
                                                        in: .userDomainMask,
                                                        appropriateFor: nil,
                                                        create: true)
            
            return [applicationSupportURL, cachesURL]
        }
        catch {
            print("ERROR: Failed to query / initialize URL for application support or cache directory:\n\(error)")
            return []
        }
    }()
    
    private static func uniqueURLsRequiringSecurityScope(URLs:[URL],
                                                         allowGroupingByParentURL allowGrouping:Bool,
                                                         alwaysAskForParentURLAccess alwaysAccessParentURL:Bool)
        throws -> [URL]
    {
        let inaccessibleURLs = URLs.filter { URL in
            return self.knownAccessibleDirectoryURLs.firstIndex { accessibleURL in
                return URL.path.hasPrefix(accessibleURL.path)
                } != nil
        }
        
        if inaccessibleURLs.count == 0 {
            return []
        }
        
        if !allowGrouping {
            return inaccessibleURLs
        }
        
        let groupedURLs = self.URLsGroupedByAbsoluteParentURLStrings(URLs: inaccessibleURLs)
        
        // TODO: should filter out URLs that are contained by other URLs in the array
        return groupedURLs.compactMap { (absoluteParentURLString, URLs) -> URL? in
            // If there are multiple URLs to access in a common parent folder,
            // we'll request access for that folder
            if (alwaysAccessParentURL || URLs.count > 1) {
                return URL(string:absoluteParentURLString)
            }
                // Otherwise, we'll request access for the sole URL
            else if (URLs.count == 1) {
                return URLs.first
            }
            
            return nil
        }
    }
    
    /** Determine which URLs aren't yet covered by a bookmark that we have stored by the storage delegate. */
    public func URLsRequiringSecurityScope(amongstURLs URLs:[URL]) throws -> (withoutBookmark: [URL], securityScoped: [URL]) {
        
        let allBookmarks = try self.delegate.allBookmarkDataByAbsoluteURLString()
        
        var URLsWithoutBookmarks = [URL]()
        var securityScopedURLs = [URL]()
        
        for URL in URLs {
            var found = false
            
            for absoluteBookmarkedURLString in allBookmarks.keys {
                
                if (URL.absoluteString.hasPrefix(absoluteBookmarkedURLString)) {
                    // Only way to know if the bookmark will actually work is to try resolving & starting access
                    
                    var isStale: ObjCBool = false
                    let securityScopedURL = try NSURL(resolvingBookmarkData: allBookmarks[absoluteBookmarkedURLString]!,
                                                      options: NSURL.BookmarkResolutionOptions.withSecurityScope,
                                                      relativeTo: nil,
                                                      bookmarkDataIsStale: &isStale)
                    
                    if securityScopedURL.startAccessingSecurityScopedResource() {
                        securityScopedURLs.append(securityScopedURL as URL)
                        found = true
                    }
                    else {
                        // TODO: ask storage delegate to remove failed bookmark data here!
                    }
                }
            }
            
            if !found {
                URLsWithoutBookmarks.append(URL)
            }
        }
        
        return (withoutBookmark: URLsWithoutBookmarks, securityScoped:securityScopedURLs)
    }
    
    private static func fileURL(_ URL:URL, isEqualToFileURL otherURL:URL) throws -> Bool {
        
        //
        // Note: yes, we are aware that if either URL required security-scoped access, the following can only return YES if that access is already granted, as retrieving the properties of a file won't succeed otherwise. TODO: might need to rename this method to reflect that, so that it isn't copied to some other context where that matters.
        //
        let fileManager = FileManager.default
        
        let properties = try fileManager.attributesOfItem(atPath: URL.path)
        
        let otherProperties = try fileManager.attributesOfItem(atPath: otherURL.path)
        
        guard let firstInodeNumber = properties[FileAttributeKey.systemFileNumber] as? NSNumber else {
            throw BookmarkStorageError.fileURLHasNoSystemFileNumber(URL)
        }
        
        guard let otherInodeNumber = otherProperties[FileAttributeKey.systemFileNumber] as? NSNumber else {
            throw BookmarkStorageError.fileURLHasNoSystemFileNumber(URL)
        }
        
        return firstInodeNumber == otherInodeNumber
    }
    
    func UTI(forPathExtension pathExtension: String) -> String?
    {
        if let UTI = UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension,
                                                           pathExtension.lowercased() as CFString, nil) {
            return String(UTI.takeUnretainedValue())
        }
        return nil
    }
    
    public func promptUserForSecurityScopedAccess(toURL URL:URL,
                                           withTitle title:String,
                                           message:String,
                                           prompt:String = "Choose") throws -> SecurityScopeAccessOutcome
    {
        var isProbablyADirectory:ObjCBool = false
        let path = URL.path
        let pathExtension = URL.pathExtension
        let uti = self.UTI(forPathExtension: pathExtension)
        
        if !FileManager.default.fileExists(atPath:path, isDirectory:&isProbablyADirectory) {
            return .failure
        }
        
        let panel = NSOpenPanel()
        panel.title = title
        panel.prompt = prompt
        
        panel.message =
            message
                .replacingOccurrences(of:"${filename}", with: URL.lastPathComponent)
                .replacingOccurrences(of:"${likelyFileKind}", with: isProbablyADirectory.boolValue ? "folder" : "file")
        
        panel.canChooseFiles = true
        panel.canChooseDirectories = true
        panel.allowedFileTypes = {
            if let uti = uti { return [uti, kUTTypeFolder as String] }
            return [kUTTypeFolder as String]
        }()
        panel.allowsOtherFileTypes = true
        panel.delegate = nil
        panel.canCreateDirectories = false
        panel.allowsMultipleSelection = false
        
        // Use (lack of) extension as best guess at pre-determining
        // whether URL points to a directory or a regular file
        
        var containingDirURL = URL; containingDirURL.deleteLastPathComponent()
        
        panel.directoryURL = isProbablyADirectory.boolValue ? URL : containingDirURL
        
        var chosenURL:URL? = nil
        
        repeat {
            let result = panel.runModal()
            
            if result != NSApplication.ModalResponse.stop {
                return .cancelled
            }
            
            if let panelURL = panel.url {
                var containingDirectoryURL = URL; containingDirectoryURL.deleteLastPathComponent()
                
                // We accept both if user chose the URL we asked for, or its containing directory
                let expectedURL = { () -> Bool in
                    do {
                        let matches = try type(of:self).fileURL(URL, isEqualToFileURL:panelURL)
                        if matches {
                            return true
                        }
                        return try type(of:self).fileURL(containingDirectoryURL, isEqualToFileURL:panelURL)
                    }
                    catch {
                        return false
                    }
                }()
                
                if expectedURL {
                    chosenURL = panelURL
                }
                
            }
            
        } while chosenURL == nil
        
        let data = try (chosenURL! as NSURL).bookmarkData(options: NSURL.BookmarkCreationOptions.withSecurityScope,
                                                          includingResourceValuesForKeys: nil,
                                                          relativeTo: nil)
        return .success(bookmarkData: data)
    }
    
    /** Read from, or write to, given URLs with security-scoped access. */
    public func accessURLs(_ URLAccessObjects:[URLAccess],
                           withUserPromptTitle openPanelTitle:String,
                           description openPanelDescription:String,
                           prompt:String,
                           options:URLAccessOptions,
                           accessHandler:URLAccessHandler) throws {
        
        // Gather all URLs that will be accessed
        let allURLsToAccess = URLAccessObjects.flatMap { $0.URLs }
        
        let URLsNeedingSecurityScopedAccess
            = try type(of: self)
                .uniqueURLsRequiringSecurityScope(URLs: allURLsToAccess,
                                                  allowGroupingByParentURL:
                    options.contains(URLAccessOptions.groupAccessByParentDirectoryURL),
                                                  alwaysAskForParentURLAccess:
                    options.contains(URLAccessOptions.alwaysAskForAccessToParentDirectory))
        
        let (URLsToBookmark, _)
            = try self.URLsRequiringSecurityScope(amongstURLs: URLsNeedingSecurityScopedAccess)
        
        // Ask user to pick URLs we need access to
        for URL in URLsToBookmark {
            let result = try self.promptUserForSecurityScopedAccess(toURL: URL,
                                                                    withTitle: openPanelTitle,
                                                                    message: openPanelDescription,
                                                                    prompt:prompt)
            
            switch result {
            case .success(let bookmarkData):
                try self.delegate.saveBookmark(data: bookmarkData, forURL: URL)
                
            case .cancelled:
                throw BookmarkStorageError.userCancelled
                
            case .failure:
                break
            }
        }
        
        for accessObject in URLAccessObjects {
            if let accessError = accessHandler(accessObject) {
                throw accessError
            }
        }
    }
    
    // TODO: stop accessing security-scoped URLs resolved above?
}
