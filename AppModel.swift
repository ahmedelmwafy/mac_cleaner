import Foundation
import SwiftUI
import AppKit

class AppModel: ObservableObject {
    @Published var isScanning = false
    @Published var isCleaning = false
    
    // Scanned categories mapping
    @Published var categoryItems: [ScanCategoryType: [CleanableItem]] = [:]
    
    // Custom folder variables
    @Published var customFolderURL: URL? = nil
    @Published var customFolderPath: String = ""
    
    // Settings
    @Published var deletePermanently: Bool = false // false means move to trash
    
    // Logs for console drawer
    @Published var logs: [String] = []
    
    // Navigation / Current view selection
    @Published var selectedCategory: ScanCategoryType = .dashboard
    
    // Clean success state
    @Published var showCleanSuccess = false
    @Published var cleanedItemsCount = 0
    @Published var cleanedBytes: Int64 = 0
    
    init() {
        // Initialize empty lists
        for cat in ScanCategoryType.allCases {
            categoryItems[cat] = []
        }
    }
    
    // Helper to log messages in real-time
    func log(_ message: String) {
        DispatchQueue.main.async {
            let timestamp = DateFormatter.localizedString(from: Date(), dateStyle: .none, timeStyle: .medium)
            self.logs.append("[\(timestamp)] \(message)")
            // Limit logs to last 1000 items
            if self.logs.count > 1000 {
                self.logs.removeFirst()
            }
        }
    }
    
    func clearLogs() {
        DispatchQueue.main.async {
            self.logs.removeAll()
        }
    }
    
    // Scans all standard categories
    func scanAll() {
        guard !isScanning else { return }
        isScanning = true
        clearLogs()
        log("Starting system-wide scan...")
        
        let categoriesToScan = ScanCategoryType.allCases.filter { $0 != .custom && $0 != .dashboard }
        
        DispatchQueue.global(qos: .userInitiated).async {
            for category in categoriesToScan {
                self.log("Scanning category: \(category.rawValue)...")
                let items = Scanner.shared.scanStandardCategory(category: category) { msg in
                    self.log(msg)
                }
                DispatchQueue.main.async {
                    self.categoryItems[category] = items
                }
            }
            
            // If custom folder is set, scan it too
            if let customURL = self.customFolderURL {
                self.log("Rescanning custom folder \(customURL.path)...")
                let items = Scanner.shared.scanCustomDirectory(at: customURL) { msg in
                    self.log(msg)
                }
                DispatchQueue.main.async {
                    self.categoryItems[.custom] = items
                }
            }
            
            DispatchQueue.main.async {
                self.isScanning = false
                self.log("System scan completed successfully.")
            }
        }
    }
    
    // Scans a single category
    func scanCategory(_ category: ScanCategoryType) {
        guard !isScanning else { return }
        
        if category == .custom {
            selectAndScanCustomFolder()
            return
        }
        
        isScanning = true
        clearLogs()
        log("Starting scan of \(category.rawValue)...")
        
        DispatchQueue.global(qos: .userInitiated).async {
            let items = Scanner.shared.scanStandardCategory(category: category) { msg in
                self.log(msg)
            }
            DispatchQueue.main.async {
                self.categoryItems[category] = items
                self.isScanning = false
                self.log("\(category.rawValue) scan completed.")
            }
        }
    }
    
    // Opens standard macOS NSOpenPanel folder picker and scans the chosen directory
    func selectAndScanCustomFolder() {
        let panel = NSOpenPanel()
        panel.title = "Select Folder to Scan"
        panel.showsHiddenFiles = true // Allow selecting hidden folders if needed
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.allowsMultipleSelection = false
        
        // Bring to front
        NSApp.activate(ignoringOtherApps: true)
        
        if panel.runModal() == .OK, let url = panel.url {
            self.customFolderURL = url
            self.customFolderPath = url.path
            self.selectedCategory = .custom
            self.isScanning = true
            self.clearLogs()
            
            self.log("Selected custom directory: \(url.path)")
            self.log("Starting deep scan (including hidden files)...")
            
            DispatchQueue.global(qos: .userInitiated).async {
                let items = Scanner.shared.scanCustomDirectory(at: url) { msg in
                    self.log(msg)
                }
                DispatchQueue.main.async {
                    self.categoryItems[.custom] = items
                    self.isScanning = false
                    self.log("Custom folder scan completed. Found \(items.count) files.")
                }
            }
        }
    }
    
    // Returns total bytes scanned across selected category (or all if specified)
    func totalScannedSize(for category: ScanCategoryType? = nil) -> Int64 {
        if let cat = category {
            return categoryItems[cat]?.reduce(0) { $0 + $1.size } ?? 0
        } else {
            return categoryItems.values.flatMap { $0 }.reduce(0) { $0 + $1.size }
        }
    }
    
    // Returns selected bytes to clean
    func totalSelectedSize(for category: ScanCategoryType? = nil) -> Int64 {
        if let cat = category {
            return categoryItems[cat]?.filter { $0.isSelected }.reduce(0) { $0 + $1.size } ?? 0
        } else {
            return categoryItems.values.flatMap { $0 }.filter { $0.isSelected }.reduce(0) { $0 + $1.size }
        }
    }
    
    // Selection operations
    func toggleItemSelection(category: ScanCategoryType, itemId: String) {
        guard let items = categoryItems[category] else { return }
        categoryItems[category] = items.map { item in
            if item.id == itemId {
                var newItem = item
                newItem.isSelected.toggle()
                return newItem
            }
            return item
        }
    }
    
    func selectAll(for category: ScanCategoryType, selected: Bool) {
        guard let items = categoryItems[category] else { return }
        categoryItems[category] = items.map { item in
            var newItem = item
            newItem.isSelected = selected
            return newItem
        }
        log("\(selected ? "Selected" : "Deselected") all items in \(category.rawValue).")
    }
    
    func selectHiddenOnly(for category: ScanCategoryType, selected: Bool) {
        guard let items = categoryItems[category] else { return }
        categoryItems[category] = items.map { item in
            var newItem = item
            if item.isHidden {
                newItem.isSelected = selected
            }
            return newItem
        }
        log("\(selected ? "Selected" : "Deselected") all hidden files in \(category.rawValue).")
    }
    
    func selectVisibleOnly(for category: ScanCategoryType, selected: Bool) {
        guard let items = categoryItems[category] else { return }
        categoryItems[category] = items.map { item in
            var newItem = item
            if !item.isHidden {
                newItem.isSelected = selected
            }
            return newItem
        }
        log("\(selected ? "Selected" : "Deselected") all visible files in \(category.rawValue).")
    }
    
    // Clean operation
    func cleanSelected() {
        guard !isCleaning else { return }
        
        let allSelectedItems = categoryItems.flatMap { (cat, items) in
            items.filter { $0.isSelected }
        }
        
        if allSelectedItems.isEmpty {
            log("No items selected for cleaning.")
            return
        }
        
        isCleaning = true
        clearLogs()
        log("Starting cleaning process...")
        log("Deleting \(allSelectedItems.count) items...")
        
        DispatchQueue.global(qos: .userInitiated).async {
            let result = Scanner.shared.deleteItems(allSelectedItems, permanently: self.deletePermanently) { msg in
                self.log(msg)
            }
            
            // Remove successfully cleaned items from lists
            DispatchQueue.main.async {
                for (cat, items) in self.categoryItems {
                    // Filter out items that were selected and deleted
                    self.categoryItems[cat] = items.filter { item in
                        // Keep item if it wasn't selected (and thus not deleted)
                        !item.isSelected
                    }
                }
                
                self.cleanedItemsCount = result.deletedCount
                self.cleanedBytes = result.sizeCleaned
                self.isCleaning = false
                self.showCleanSuccess = true
                self.log("Cleaning complete! Removed \(result.deletedCount) items, freed \(ByteCountFormatter.string(fromByteCount: result.sizeCleaned, countStyle: .file)).")
            }
        }
    }
}
