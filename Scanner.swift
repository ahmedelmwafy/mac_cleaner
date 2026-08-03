import Foundation

enum ScanCategoryType: String, CaseIterable, Identifiable {
    case dashboard = "Dashboard"
    case userCaches = "User Caches"
    case systemCaches = "System Caches"
    case userLogs = "User Logs"
    case phpCache = "PHP Cache"
    case nodeCache = "Node.js Cache"
    case pythonCache = "Python & Dev Caches"
    case xcodeJunk = "Xcode DerivedData"
    case gradleCache = "Gradle Cache"
    case androidCache = "Android Cache"
    case devProjects = "Project Builds"
    case trash = "System Trash"
    case custom = "Custom Folder"
    
    var id: String { self.rawValue }
}

struct CleanableItem: Identifiable, Equatable {
    let id: String // Absolute path
    let url: URL
    let name: String
    let size: Int64
    let isDirectory: Bool
    let isHidden: Bool
    var isSelected: Bool = true
    
    var formattedSize: String {
        ByteCountFormatter.string(fromByteCount: size, countStyle: .file)
    }
}

class Scanner {
    static let shared = Scanner()
    
    private init() {}
    
    // Resolves standard system/developer folders
    func getPaths(for category: ScanCategoryType) -> [URL] {
        let fm = FileManager.default
        let home = fm.homeDirectoryForCurrentUser
        switch category {
        case .dashboard:
            return []
        case .userCaches:
            if let cache = fm.urls(for: .cachesDirectory, in: .userDomainMask).first {
                return [cache]
            }
            return []
        case .systemCaches:
            return [URL(fileURLWithPath: "/Library/Caches")]
        case .userLogs:
            return [home.appendingPathComponent("Library/Logs")]
        case .phpCache:
            var paths: [URL] = []
            let composer = home.appendingPathComponent(".composer/cache")
            if fm.fileExists(atPath: composer.path) { paths.append(composer) }
            let phpCache = home.appendingPathComponent(".php/cache")
            if fm.fileExists(atPath: phpCache.path) { paths.append(phpCache) }
            let tmp = URL(fileURLWithPath: "/tmp")
            if let contents = try? fm.contentsOfDirectory(at: tmp, includingPropertiesForKeys: nil, options: []) {
                for url in contents {
                    if url.lastPathComponent.hasPrefix("php") {
                        paths.append(url)
                    }
                }
            }
            return paths
        case .nodeCache:
            var paths: [URL] = []
            let npm = home.appendingPathComponent(".npm")
            if fm.fileExists(atPath: npm.path) { paths.append(npm) }
            let yarn = home.appendingPathComponent(".yarn/cache")
            if fm.fileExists(atPath: yarn.path) { paths.append(yarn) }
            let pnpm = home.appendingPathComponent(".pnpm-store")
            if fm.fileExists(atPath: pnpm.path) { paths.append(pnpm) }
            let bun = home.appendingPathComponent(".bun/install/cache")
            if fm.fileExists(atPath: bun.path) { paths.append(bun) }
            let gyp = home.appendingPathComponent(".node-gyp")
            if fm.fileExists(atPath: gyp.path) { paths.append(gyp) }
            return paths
        case .pythonCache:
            var paths: [URL] = []
            let pip = home.appendingPathComponent("Library/Caches/pip")
            if fm.fileExists(atPath: pip.path) { paths.append(pip) }
            let poetry = home.appendingPathComponent("Library/Caches/pypoetry")
            if fm.fileExists(atPath: poetry.path) { paths.append(poetry) }
            let cocoapods = home.appendingPathComponent("Library/Caches/CocoaPods")
            if fm.fileExists(atPath: cocoapods.path) { paths.append(cocoapods) }
            let swiftpm = home.appendingPathComponent("Library/Caches/org.swift.swiftpm")
            if fm.fileExists(atPath: swiftpm.path) { paths.append(swiftpm) }
            let cargo = home.appendingPathComponent(".cargo/registry")
            if fm.fileExists(atPath: cargo.path) { paths.append(cargo) }
            let gomod = home.appendingPathComponent("go/pkg/mod")
            if fm.fileExists(atPath: gomod.path) { paths.append(gomod) }
            return paths
        case .xcodeJunk:
            return [home.appendingPathComponent("Library/Developer/Xcode/DerivedData")]
        case .gradleCache:
            return [home.appendingPathComponent(".gradle/caches")]
        case .androidCache:
            var paths: [URL] = []
            let dotAndroid = home.appendingPathComponent(".android/cache")
            if fm.fileExists(atPath: dotAndroid.path) {
                paths.append(dotAndroid)
            }
            let googleCaches = home.appendingPathComponent("Library/Caches/Google")
            if let contents = try? fm.contentsOfDirectory(at: googleCaches, includingPropertiesForKeys: nil, options: []) {
                for url in contents {
                    if url.lastPathComponent.hasPrefix("AndroidStudio") {
                        paths.append(url)
                    }
                }
            }
            return paths
        case .trash:
            return [home.appendingPathComponent(".Trash")]
        case .devProjects:
            return []
        case .custom:
            return []
        }
    }
    
    // Scans a standard category (scans first-level items and calculates size recursively for directories)
    func scanStandardCategory(category: ScanCategoryType, logHandler: @escaping (String) -> Void) -> [CleanableItem] {
        if category == .dashboard {
            return []
        }
        if category == .devProjects {
            return scanDeveloperProjects(logHandler: logHandler)
        }
        let rootURLs = getPaths(for: category)
        var allItems: [CleanableItem] = []
        for url in rootURLs {
            if FileManager.default.fileExists(atPath: url.path) {
                let items = scanDirectoryContents(at: url, recursiveForItems: false, logHandler: logHandler)
                allItems.append(contentsOf: items)
            }
        }
        allItems.sort { $0.size > $1.size }
        return allItems
    }
    
    // Scans directories up to depth 3 to locate developer project build artifacts
    func scanDeveloperProjects(logHandler: @escaping (String) -> Void) -> [CleanableItem] {
        let fm = FileManager.default
        let home = fm.homeDirectoryForCurrentUser
        
        let searchRoots = [
            home.appendingPathComponent("Desktop"),
            home.appendingPathComponent("Documents"),
            home.appendingPathComponent("Projects"),
            home.appendingPathComponent("Workspace"),
            home.appendingPathComponent("src")
        ]
        
        var cleanableItems: [CleanableItem] = []
        
        for root in searchRoots {
            guard fm.fileExists(atPath: root.path) else { continue }
            logHandler("Searching for project builds in \(root.path)...")
            findProjects(in: root, depth: 0, maxDepth: 3, cleanableItems: &cleanableItems, logHandler: logHandler)
        }
        
        cleanableItems.sort { $0.size > $1.size }
        return cleanableItems
    }
    
    private func findProjects(in directory: URL, depth: Int, maxDepth: Int, cleanableItems: inout [CleanableItem], logHandler: @escaping (String) -> Void) {
        guard depth <= maxDepth else { return }
        
        let fm = FileManager.default
        let properties: [URLResourceKey] = [.isDirectoryKey, .isHiddenKey]
        
        guard let contents = try? fm.contentsOfDirectory(
            at: directory,
            includingPropertiesForKeys: properties,
            options: [.skipsHiddenFiles]
        ) else {
            return
        }
        
        var isProject = false
        var projectItems: [(name: String, subURL: URL, isDir: Bool)] = []
        
        let fileNames = contents.map { $0.lastPathComponent }
        
        // 1. Flutter Project Check
        if fileNames.contains("pubspec.yaml") {
            isProject = true
            let buildURL = directory.appendingPathComponent("build")
            let dartToolURL = directory.appendingPathComponent(".dart_tool")
            
            if fm.fileExists(atPath: buildURL.path) {
                projectItems.append((name: "Flutter Build (build/)", subURL: buildURL, isDir: true))
            }
            if fm.fileExists(atPath: dartToolURL.path) {
                projectItems.append((name: "Flutter Dart Tool (.dart_tool/)", subURL: dartToolURL, isDir: true))
            }
        }
        
        // 2. Node.js Project Check (if not already classified)
        if !isProject && fileNames.contains("package.json") {
            isProject = true
            let nodeModulesURL = directory.appendingPathComponent("node_modules")
            let nextBuildURL = directory.appendingPathComponent(".next")
            let nuxtBuildURL = directory.appendingPathComponent(".nuxt")
            let distURL = directory.appendingPathComponent("dist")
            
            if fm.fileExists(atPath: nodeModulesURL.path) {
                projectItems.append((name: "Node Modules (node_modules/)", subURL: nodeModulesURL, isDir: true))
            }
            if fm.fileExists(atPath: nextBuildURL.path) {
                projectItems.append((name: "Next.js Build (.next/)", subURL: nextBuildURL, isDir: true))
            }
            if fm.fileExists(atPath: nuxtBuildURL.path) {
                projectItems.append((name: "Nuxt.js Build (.nuxt/)", subURL: nuxtBuildURL, isDir: true))
            }
            if fm.fileExists(atPath: distURL.path) {
                projectItems.append((name: "JS Build Output (dist/)", subURL: distURL, isDir: true))
            }
        }
        
        // 3. Gradle Project Check (if not inside Flutter project)
        if !isProject && (fileNames.contains("build.gradle") || fileNames.contains("build.gradle.kts") || fileNames.contains("settings.gradle")) {
            isProject = true
            let buildURL = directory.appendingPathComponent("build")
            let appBuildURL = directory.appendingPathComponent("app/build")
            
            if fm.fileExists(atPath: buildURL.path) {
                projectItems.append((name: "Gradle Build (build/)", subURL: buildURL, isDir: true))
            }
            if fm.fileExists(atPath: appBuildURL.path) {
                projectItems.append((name: "Gradle App Build (app/build/)", subURL: appBuildURL, isDir: true))
            }
        }
        
        // 4. Swift Package Check
        if !isProject && fileNames.contains("Package.swift") {
            isProject = true
            let buildURL = directory.appendingPathComponent(".build")
            if fm.fileExists(atPath: buildURL.path) {
                projectItems.append((name: "Swift Package Build (.build/)", subURL: buildURL, isDir: true))
            }
        }
        
        // 5. Xcode/iOS project (if not Gradle or JS)
        if !isProject && (fileNames.contains { $0.hasSuffix(".xcodeproj") || $0.hasSuffix(".xcworkspace") }) {
            let podsURL = directory.appendingPathComponent("Pods")
            let buildURL = directory.appendingPathComponent("build")
            if fm.fileExists(atPath: podsURL.path) {
                projectItems.append((name: "CocoaPods (Pods/)", subURL: podsURL, isDir: true))
            }
            if fm.fileExists(atPath: buildURL.path) {
                projectItems.append((name: "Xcode Local Build", subURL: buildURL, isDir: true))
            }
        }
        
        // 6. PHP Project Check (Composer, Laravel, Symfony)
        if !isProject && (fileNames.contains("composer.json") || fileNames.contains("artisan")) {
            isProject = true
            let vendorURL = directory.appendingPathComponent("vendor")
            let laravelCacheURL = directory.appendingPathComponent("storage/framework/cache")
            let laravelViewsURL = directory.appendingPathComponent("storage/framework/views")
            let laravelSessionsURL = directory.appendingPathComponent("storage/framework/sessions")
            let bootstrapCacheURL = directory.appendingPathComponent("bootstrap/cache")
            
            if fm.fileExists(atPath: vendorURL.path) {
                projectItems.append((name: "PHP Vendor (vendor/)", subURL: vendorURL, isDir: true))
            }
            if fm.fileExists(atPath: laravelCacheURL.path) {
                projectItems.append((name: "Laravel Framework Cache", subURL: laravelCacheURL, isDir: true))
            }
            if fm.fileExists(atPath: laravelViewsURL.path) {
                projectItems.append((name: "Laravel Compiled Views", subURL: laravelViewsURL, isDir: true))
            }
            if fm.fileExists(atPath: laravelSessionsURL.path) {
                projectItems.append((name: "Laravel Sessions", subURL: laravelSessionsURL, isDir: true))
            }
            if fm.fileExists(atPath: bootstrapCacheURL.path) {
                projectItems.append((name: "Bootstrap Cache", subURL: bootstrapCacheURL, isDir: true))
            }
        }
        
        // 7. Python Project Check (virtualenvs, cache)
        if !isProject && (fileNames.contains("requirements.txt") || fileNames.contains("pyproject.toml") || fileNames.contains("Pipfile") || fileNames.contains("setup.py")) {
            isProject = true
            let venvURL = directory.appendingPathComponent(".venv")
            let venvAltURL = directory.appendingPathComponent("venv")
            let pycacheURL = directory.appendingPathComponent("__pycache__")
            let pytestURL = directory.appendingPathComponent(".pytest_cache")
            
            if fm.fileExists(atPath: venvURL.path) {
                projectItems.append((name: "Python Virtual Env (.venv/)", subURL: venvURL, isDir: true))
            }
            if fm.fileExists(atPath: venvAltURL.path) {
                projectItems.append((name: "Python Virtual Env (venv/)", subURL: venvAltURL, isDir: true))
            }
            if fm.fileExists(atPath: pycacheURL.path) {
                projectItems.append((name: "Python Bytecode (__pycache__/)", subURL: pycacheURL, isDir: true))
            }
            if fm.fileExists(atPath: pytestURL.path) {
                projectItems.append((name: "Pytest Cache (.pytest_cache/)", subURL: pytestURL, isDir: true))
            }
        }
        
        // 8. Rust Project Check
        if !isProject && fileNames.contains("Cargo.toml") {
            isProject = true
            let targetURL = directory.appendingPathComponent("target")
            if fm.fileExists(atPath: targetURL.path) {
                projectItems.append((name: "Rust Build Target (target/)", subURL: targetURL, isDir: true))
            }
        }
        
        // If we found project items, add them
        if !projectItems.isEmpty {
            let projectName = directory.lastPathComponent
            for pItem in projectItems {
                let size = getDirectorySize(at: pItem.subURL)
                if size > 0 {
                    let cleanableItem = CleanableItem(
                        id: pItem.subURL.path,
                        url: pItem.subURL,
                        name: "[\(projectName)] \(pItem.name)",
                        size: size,
                        isDirectory: pItem.isDir,
                        isHidden: pItem.subURL.lastPathComponent.hasPrefix(".")
                    )
                    cleanableItems.append(cleanableItem)
                    logHandler("Found Project Build Item: \(cleanableItem.name) (\(cleanableItem.formattedSize))")
                }
            }
        }
        
        // If this directory is a project, do not search deeper
        if isProject {
            return
        }
        
        // Recurse
        for url in contents {
            autoreleasepool {
                if let resourceValues = try? url.resourceValues(forKeys: [.isDirectoryKey, .isHiddenKey]),
                   let isDir = resourceValues.isDirectory, isDir,
                   let isHidden = resourceValues.isHidden, !isHidden {
                    
                    let folderName = url.lastPathComponent
                    // Avoid scanning system or cache directories to be fast
                    if ["Library", "Applications", "System", "Pictures", "Music", "Movies", "Downloads", ".git", ".gradle", "node_modules", "build"].contains(folderName) {
                        return
                    }
                    
                    findProjects(in: url, depth: depth + 1, maxDepth: maxDepth, cleanableItems: &cleanableItems, logHandler: logHandler)
                }
            }
        }
    }
    
    // Scans a custom directory, recursively listing all files (including hidden files)
    func scanCustomDirectory(at rootURL: URL, logHandler: @escaping (String) -> Void) -> [CleanableItem] {
        return scanDirectoryContents(at: rootURL, recursiveForItems: true, logHandler: logHandler)
    }
    
    // Shared scanner implementation
    private func scanDirectoryContents(at rootURL: URL, recursiveForItems: Bool, logHandler: @escaping (String) -> Void) -> [CleanableItem] {
        let fm = FileManager.default
        var items: [CleanableItem] = []
        
        logHandler("Scanning \(rootURL.path)...")
        
        do {
            // Get contents of root directory
            let properties: [URLResourceKey] = [.isDirectoryKey, .isHiddenKey, .fileSizeKey]
            
            if recursiveForItems {
                // Recursive scan for all individual files (e.g. for custom scanner)
                guard let enumerator = fm.enumerator(
                    at: rootURL,
                    includingPropertiesForKeys: properties,
                    options: [], // Include hidden files
                    errorHandler: { url, error in
                        logHandler("Error accessing \(url.lastPathComponent): \(error.localizedDescription)")
                        return true
                    }
                ) else {
                    return []
                }
                
                for case let fileURL as URL in enumerator {
                    autoreleasepool {
                        let path = fileURL.path
                        let name = fileURL.lastPathComponent
                        
                        // Skip if it's a directory (we only list individual files in recursive mode)
                        var isDir: ObjCBool = false
                        guard fm.fileExists(atPath: path, isDirectory: &isDir) else { return }
                        if isDir.boolValue { return }
                        
                        let isHidden = name.hasPrefix(".") || (try? fileURL.resourceValues(forKeys: [.isHiddenKey]).isHidden) ?? false
                        let fileSize = (try? fileURL.resourceValues(forKeys: [.fileSizeKey]).fileSize) ?? 0
                        
                        let item = CleanableItem(
                            id: path,
                            url: fileURL,
                            name: name,
                            size: Int64(fileSize),
                            isDirectory: false,
                            isHidden: isHidden
                        )
                        items.append(item)
                        
                        if items.count % 50 == 0 {
                            logHandler("Found \(items.count) files... (Current: \(name))")
                        }
                    }
                }
            } else {
                // First-level scan (for system folders like caches, so we don't display 10,000 files)
                let contents = try fm.contentsOfDirectory(
                    at: rootURL,
                    includingPropertiesForKeys: properties,
                    options: [] // Include hidden files
                )
                
                for itemURL in contents {
                    autoreleasepool {
                        let path = itemURL.path
                        let name = itemURL.lastPathComponent
                        
                        var isDir: ObjCBool = false
                        guard fm.fileExists(atPath: path, isDirectory: &isDir) else { return }
                        
                        let isHidden = name.hasPrefix(".") || (try? itemURL.resourceValues(forKeys: [.isHiddenKey]).isHidden) ?? false
                        
                        var size: Int64 = 0
                        if isDir.boolValue {
                            size = getDirectorySize(at: itemURL)
                        } else {
                            size = Int64((try? itemURL.resourceValues(forKeys: [.fileSizeKey]).fileSize) ?? 0)
                        }
                        
                        let item = CleanableItem(
                            id: path,
                            url: itemURL,
                            name: name,
                            size: size,
                            isDirectory: isDir.boolValue,
                            isHidden: isHidden
                        )
                        items.append(item)
                        logHandler("Scanned item: \(name) (\(item.formattedSize))")
                    }
                }
            }
        } catch {
            logHandler("Failed to scan directory: \(error.localizedDescription)")
        }
        
        // Sort items by size descending
        items.sort { $0.size > $1.size }
        logHandler("Scanning complete! Found \(items.count) cleanable items.")
        return items
    }
    
    // Calculates directory size recursively
    private func getDirectorySize(at url: URL) -> Int64 {
        let fm = FileManager.default
        var size: Int64 = 0
        let properties: [URLResourceKey] = [.fileSizeKey, .isDirectoryKey]
        
        guard let enumerator = fm.enumerator(
            at: url,
            includingPropertiesForKeys: properties,
            options: [],
            errorHandler: nil
        ) else {
            return 0
        }
        
        for case let fileURL as URL in enumerator {
            autoreleasepool {
                if let resourceValues = try? fileURL.resourceValues(forKeys: [.fileSizeKey, .isDirectoryKey]) {
                    if let isDirectory = resourceValues.isDirectory, !isDirectory {
                        size += Int64(resourceValues.fileSize ?? 0)
                    }
                }
            }
        }
        
        return size
    }
    
    // Deletes selected files. Returns the count of successfully deleted items and total size cleaned.
    func deleteItems(_ items: [CleanableItem], permanently: Bool, logHandler: @escaping (String) -> Void) -> (deletedCount: Int, sizeCleaned: Int64) {
        let fm = FileManager.default
        var deletedCount = 0
        var sizeCleaned: Int64 = 0
        
        for item in items {
            logHandler("Deleting: \(item.url.path)...")
            do {
                if permanently {
                    try fm.removeItem(at: item.url)
                    deletedCount += 1
                    sizeCleaned += item.size
                    logHandler("Permanently deleted: \(item.name)")
                } else {
                    // Move to Trash
                    try fm.trashItem(at: item.url, resultingItemURL: nil)
                    deletedCount += 1
                    sizeCleaned += item.size
                    logHandler("Moved to Trash: \(item.name)")
                }
            } catch {
                logHandler("Failed to delete \(item.name): \(error.localizedDescription)")
            }
        }
        
        return (deletedCount, sizeCleaned)
    }
}
