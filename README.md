# BookmarkStorage [![Carthage compatible](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat)](https://github.com/Carthage/Carthage)

A pure Swift API for dealing with security scoped bookmark data.

- Provides an API for persisting security scoped bookmark data, and for accessing URLs potentially requiring security scoped access.
- Bookmark data persistence is handled through a 'storage delegate' protocol.
- An `NSUserDefaults` backed implementation is provided for the storage delegate.


#### INSTALLATION

##### Carthage

[Carthage](https://github.com/Carthage/Carthage) is a decentralized dependency manager that builds your dependencies and provides you with binary frameworks.

You can install Carthage with [Homebrew](http://brew.sh/) using the following command:

```bash
$ brew update
$ brew install carthage
```

To integrate BookmarkStorage into your Xcode project using Carthage, specify it in your `Cartfile`:

```ogdl
github "mz2/BookmarkStorage" ~> 0.0.1
```

Run `carthage update` to build the framework and drag the built `BookmarkStorage.framework` into your Xcode project.

### Manually

If you prefer not to use either of the aforementioned dependency managers, you can integrate BookmarkStorage into your project manually.

#### Embedded Framework

- Open up Terminal, `cd` into your top-level project directory, and run the following command "if" your project is not initialized as a git repository:

```bash
$ git init
```

- Add BookmarkStorage as a git [submodule](http://git-scm.com/docs/git-submodule) by running the following command:

```bash
$ git submodule add https://github.com/mz2/BookmarkStorage.git
```

- Open the new `BookmarkStorage` folder, and drag the `BookmarkStorage.xcodeproj` into the Project Navigator of your application's Xcode project.

    > It should appear nested underneath your application's blue project icon. Whether it is above or below all the other Xcode groups does not matter.

- Select the `BookmarkStorage.xcodeproj` in the Project Navigator and verify the deployment target matches that of your application target.
- Next, select your application project in the Project Navigator (blue project icon) to navigate to the target configuration window and select the application target under the "Targets" heading in the sidebar.
- In the tab bar at the top of that window, open the "General" panel.
- Click on the `+` button under the "Embedded Binaries" section.
- Select the `BookmarkStorage.xcodeproj` nested inside a `Products` folder now visible.

> The `BookmarkStorage.framework` is automagically added as a target dependency, linked framework and embedded framework in a copy files build phase which is all you need to build on the simulator and a device.

(This manual installation section was shamelessly ripped from the excellent [Alamofire](github.com/alamofire/Alamofire) instructions.)

#### USAGE

Adapting from a test included in the test suite for the framework, here's how you can use BookmarkStorage:

1. Construct a `BookmarkStore`:

```
let bookmarkStore = BookmarkStore(delegate:UserDefaultsBookmarkStorageDelegate())
```

2. Wrap the URL(s) you wish to access into an object conforming to `URLAccess`. A reference `SimpleURLAccess` struct is provided:

```
let URLAccess = SimpleURLAccess()
```

3. Access the URL:

```
// The `description` argument accepts template strings that are replaced automatically if encountered as a substring in the paramter value.
// ${likelyFileKind}: either 'file' or 'folder' based on whether the file is thought to be a folder or not.
// ${filename}: the filename (last path component of the URL being requested may be the containing folder or the file passed in as the URL to access)
// 

// if multiple URLs are passed in, you can optionally group accesses so only one Open dialog is shown per containing directory… and to always ask for the containing directory rather than the file itself (useful if you're going to soon need to otherwise ask the user again for other files in the same directory).
let options:URLAccessOptions = .groupAccessByParentDirectoryURL
							   .union(.alwaysAskForAccessToParentDirectory)

try bookmarkStore.accessURLs([ URLAccess ],
                             withUserPromptTitle:"Title for the open panel prompt, if own shown at all.",
                             description:"Description shown in the open dialog, if one is shown at all.",
                             options:options,
                             accessHandler:{ … block where you return either nil or an error if an error occurred …})
```

You can also call `promptUserForSecurityScopedAccess` on the bookmark store to directly prompt user for security scoped bookmark data.
