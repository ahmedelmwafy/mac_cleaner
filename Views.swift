import SwiftUI
import AppKit

// A helper view to inject macOS native window vibrancy (glassmorphism)
struct VisualEffectView: NSViewRepresentable {
    var material: NSVisualEffectView.Material
    var blendingMode: NSVisualEffectView.BlendingMode
    
    func makeNSView(context: Context) -> NSVisualEffectView {
        let visualEffectView = NSVisualEffectView()
        visualEffectView.material = material
        visualEffectView.blendingMode = blendingMode
        visualEffectView.state = .active
        return visualEffectView
    }
    
    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {
        nsView.material = material
        nsView.blendingMode = blendingMode
    }
}

struct Views: View {
    @ObservedObject var model: AppModel
    @State private var isLogDrawerExpanded: Bool = true
    
    var body: some View {
        NavigationView {
            // Sidebar View
            SidebarView(model: model)
                .frame(minWidth: 220, idealWidth: 250, maxWidth: 300)
            
            // Detail View (Main Panel)
            MainPanelView(model: model, isLogDrawerExpanded: $isLogDrawerExpanded)
        }
        .frame(minWidth: 900, minHeight: 650)
        .background(VisualEffectView(material: .underWindowBackground, blendingMode: .behindWindow))
    }
}

// MARK: - Sidebar View
struct SidebarView: View {
    @ObservedObject var model: AppModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // App Title / Branding Header
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(LinearGradient(colors: [.blue, .purple], startPoint: .topLeading, endPoint: .bottomTrailing))
                        .frame(width: 32, height: 32)
                        .shadow(color: .blue.opacity(0.3), radius: 6)
                    
                    Image(systemName: "sparkles")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("MacCleaner")
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                    Text("Developer Edition")
                        .font(.system(size: 9))
                        .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 24)
            .padding(.bottom, 20)
            
            // Circular Ring Dashboard / Total Size Scanned
            VStack(spacing: 12) {
                let totalSize = model.totalScannedSize()
                let totalSizeFormatted = ByteCountFormatter.string(fromByteCount: totalSize, countStyle: .file)
                
                ZStack {
                    Circle()
                        .stroke(Color.primary.opacity(0.04), lineWidth: 6)
                        .frame(width: 80, height: 80)
                    
                    Circle()
                        .trim(from: 0.0, to: model.isScanning ? 0.3 : (totalSize > 0 ? 1.0 : 0.0))
                        .stroke(
                            LinearGradient(
                                colors: [.blue, .purple],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            style: StrokeStyle(lineWidth: 6, lineCap: .round)
                        )
                        .frame(width: 80, height: 80)
                        .rotationEffect(Angle(degrees: -90))
                        .shadow(color: .blue.opacity(0.3), radius: 6)
                        .animation(model.isScanning ? Animation.linear(duration: 1.5).repeatForever(autoreverses: false) : .default, value: model.isScanning)
                    
                    VStack(spacing: 2) {
                        Image(systemName: model.isScanning ? "arrow.triangle.2.circlepath" : "leaf.fill")
                            .font(.system(size: 18))
                            .foregroundColor(.blue)
                            .rotationEffect(Angle(degrees: model.isScanning ? 360 : 0))
                            .animation(model.isScanning ? Animation.linear(duration: 2).repeatForever(autoreverses: false) : .default, value: model.isScanning)
                    }
                }
                
                VStack(spacing: 2) {
                    Text(totalSizeFormatted)
                        .font(.system(size: 13, weight: .semibold, design: .monospaced))
                    
                    Text("Total Junk Scanned")
                        .font(.system(size: 9))
                        .foregroundColor(.secondary)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(Color.primary.opacity(0.02))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.primary.opacity(0.04), lineWidth: 1)
            )
            .padding(.horizontal, 16)
            .padding(.bottom, 20)
            
            // Scanner Categories List
            Text("SECTIONS")
                .font(.system(size: 9, weight: .bold))
                .foregroundColor(.secondary)
                .padding(.horizontal, 20)
                .padding(.bottom, 6)
            
            List(selection: $model.selectedCategory) {
                ForEach(ScanCategoryType.allCases) { cat in
                    SidebarCategoryRow(category: cat, model: model)
                        .tag(cat)
                }
            }
            .listStyle(SidebarListStyle())
            
            Spacer()
            
            // Sidebar Footer Scan Action
            VStack(spacing: 8) {
                Button(action: {
                    model.scanAll()
                }) {
                    HStack {
                        Image(systemName: "magnifyingglass")
                        Text("Scan System")
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                }
                .buttonStyle(.borderedProminent)
                .tint(.blue)
                .disabled(model.isScanning || model.isCleaning)
                
                if model.totalSelectedSize() > 0 {
                    Button(action: {
                        model.cleanSelected()
                    }) {
                        HStack {
                            Image(systemName: "trash.fill")
                            Text("Clean Items")
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.red)
                    .disabled(model.isScanning || model.isCleaning)
                }
            }
            .padding(16)
        }
    }
}

struct SidebarCategoryRow: View {
    let category: ScanCategoryType
    @ObservedObject var model: AppModel
    
    var iconName: String {
        switch category {
        case .dashboard: return "gauge"
        case .userCaches: return "folder.badge.gearshape"
        case .systemCaches: return "cpu"
        case .userLogs: return "doc.text"
        case .xcodeJunk: return "hammer"
        case .gradleCache: return "shippingbox.fill"
        case .androidCache: return "wrench.and.screwdriver.fill"
        case .devProjects: return "folder.fill.badge.gearshape"
        case .trash: return "trash"
        case .custom: return "folder.badge.plus"
        }
    }
    
    var iconColor: Color {
        switch category {
        case .dashboard: return .blue
        case .userCaches: return .blue
        case .systemCaches: return .indigo
        case .userLogs: return .orange
        case .xcodeJunk: return .purple
        case .gradleCache: return .green
        case .androidCache: return .green
        case .devProjects: return .pink
        case .trash: return .secondary
        case .custom: return .teal
        }
    }
    
    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: iconName)
                .font(.system(size: 13))
                .foregroundColor(iconColor)
                .frame(width: 18)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(category.rawValue)
                    .font(.system(size: 12, weight: category == .dashboard ? .semibold : .medium))
                
                if category == .custom, !model.customFolderPath.isEmpty {
                    Text(URL(fileURLWithPath: model.customFolderPath).lastPathComponent)
                        .font(.system(size: 9))
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
            }
            
            Spacer()
            
            if category != .dashboard {
                let count = model.categoryItems[category]?.count ?? 0
                if count > 0 {
                    let size = model.totalScannedSize(for: category)
                    Text(ByteCountFormatter.string(fromByteCount: size, countStyle: .file))
                        .font(.system(size: 9, weight: .semibold, design: .monospaced))
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 5)
                        .padding(.vertical, 1)
                        .background(Color.primary.opacity(0.04))
                        .cornerRadius(4)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Main Panel View
struct MainPanelView: View {
    @ObservedObject var model: AppModel
    @Binding var isLogDrawerExpanded: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            if model.showCleanSuccess {
                CleanSuccessView(model: model)
            } else if model.selectedCategory == .dashboard {
                DashboardOverviewView(model: model)
                
                Divider()
                
                ConsoleDrawer(model: model, isExpanded: $isLogDrawerExpanded)
            } else {
                // Category Dashboard Header
                CategoryHeaderView(model: model)
                
                Divider()
                
                // Files List Container
                FileListView(model: model)
                
                Divider()
                
                // Console Logs Drawer
                ConsoleDrawer(model: model, isExpanded: $isLogDrawerExpanded)
            }
        }
        .background(Color(NSColor.windowBackgroundColor))
    }
}

// MARK: - Dashboard Overview View
struct DashboardOverviewView: View {
    @ObservedObject var model: AppModel
    
    let columns = [
        GridItem(.flexible(), spacing: 14),
        GridItem(.flexible(), spacing: 14)
    ]
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Welcome header / Circular gauge
                HStack(spacing: 40) {
                    let totalSize = model.totalScannedSize()
                    let totalSizeFormatted = ByteCountFormatter.string(fromByteCount: totalSize, countStyle: .file)
                    
                    // Giant Glow ring
                    ZStack {
                        Circle()
                            .stroke(Color.primary.opacity(0.03), lineWidth: 14)
                            .frame(width: 140, height: 140)
                        
                        Circle()
                            .trim(from: 0.0, to: model.isScanning ? 0.35 : (totalSize > 0 ? 1.0 : 0.0))
                            .stroke(
                                LinearGradient(
                                    colors: [.blue, .purple, .pink],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                style: StrokeStyle(lineWidth: 14, lineCap: .round)
                            )
                            .frame(width: 140, height: 140)
                            .rotationEffect(Angle(degrees: -90))
                            .shadow(color: .blue.opacity(0.2), radius: 8, x: 0, y: 4)
                            .animation(model.isScanning ? Animation.linear(duration: 1.5).repeatForever(autoreverses: false) : .spring(), value: model.isScanning)
                        
                        VStack(spacing: 4) {
                            Image(systemName: model.isScanning ? "arrow.triangle.2.circlepath" : "speedometer")
                                .font(.system(size: 26))
                                .foregroundColor(.blue)
                                .rotationEffect(Angle(degrees: model.isScanning ? 360 : 0))
                                .animation(model.isScanning ? Animation.linear(duration: 2).repeatForever(autoreverses: false) : .default, value: model.isScanning)
                            
                            Text(totalSizeFormatted)
                                .font(.system(size: 18, weight: .bold, design: .rounded))
                            
                            Text(model.isScanning ? "Scanning..." : "Cleanable Junk")
                                .font(.system(size: 10))
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    // Welcome & Recommendation Text
                    VStack(alignment: .leading, spacing: 10) {
                        Text("System Cleanliness")
                            .font(.system(size: 22, weight: .bold, design: .rounded))
                        
                        Text("Scan your Mac to identify system caches, log directories, Xcode logs, Gradle outputs, and Flutter build folders. Clean up build items safely to optimize space and compilation performance.")
                            .font(.system(size: 11.5))
                            .foregroundColor(.secondary)
                            .lineSpacing(4)
                            .frame(maxWidth: 320, alignment: .leading)
                        
                        HStack(spacing: 12) {
                            Button(action: {
                                model.scanAll()
                            }) {
                                HStack {
                                    Image(systemName: "magnifyingglass")
                                    Text("Deep Scan System")
                                }
                                .padding(.horizontal, 14)
                                .padding(.vertical, 6)
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(.blue)
                            .disabled(model.isScanning || model.isCleaning)
                            
                            if model.totalSelectedSize() > 0 {
                                Button(action: {
                                    model.cleanSelected()
                                }) {
                                    HStack {
                                        Image(systemName: "trash")
                                        Text("Clean All Selected")
                                    }
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 6)
                                }
                                .buttonStyle(.borderedProminent)
                                .tint(.red)
                                .disabled(model.isScanning || model.isCleaning)
                            }
                        }
                    }
                }
                .padding(.top, 24)
                .padding(.horizontal, 24)
                
                Divider()
                    .padding(.horizontal, 24)
                
                // Categories Grid Section
                VStack(alignment: .leading, spacing: 14) {
                    Text("CLEANUP CATEGORIES")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 24)
                    
                    LazyVGrid(columns: columns, spacing: 14) {
                        ForEach(ScanCategoryType.allCases.filter { $0 != .dashboard }) { cat in
                            DashboardGridCard(category: cat, model: model)
                        }
                    }
                    .padding(.horizontal, 24)
                }
                .padding(.bottom, 24)
            }
        }
    }
}

struct DashboardGridCard: View {
    let category: ScanCategoryType
    @ObservedObject var model: AppModel
    @State private var isHovered = false
    
    var iconName: String {
        switch category {
        case .dashboard: return "gauge"
        case .userCaches: return "folder.badge.gearshape"
        case .systemCaches: return "cpu"
        case .userLogs: return "doc.text"
        case .xcodeJunk: return "hammer"
        case .gradleCache: return "shippingbox.fill"
        case .androidCache: return "wrench.and.screwdriver.fill"
        case .devProjects: return "folder.fill.badge.gearshape"
        case .trash: return "trash"
        case .custom: return "folder.badge.plus"
        }
    }
    
    var iconColor: Color {
        switch category {
        case .dashboard: return .blue
        case .userCaches: return .blue
        case .systemCaches: return .indigo
        case .userLogs: return .orange
        case .xcodeJunk: return .purple
        case .gradleCache: return .green
        case .androidCache: return .green
        case .devProjects: return .pink
        case .trash: return .secondary
        case .custom: return .teal
        }
    }
    
    var body: some View {
        Button(action: {
            model.selectedCategory = category
        }) {
            HStack(spacing: 14) {
                // Icon Glow Card
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(iconColor.opacity(0.08))
                        .frame(width: 44, height: 44)
                    
                    Image(systemName: iconName)
                        .font(.system(size: 18))
                        .foregroundColor(iconColor)
                }
                
                VStack(alignment: .leading, spacing: 3) {
                    Text(category.rawValue)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.primary)
                    
                    let size = model.totalScannedSize(for: category)
                    let itemsCount = model.categoryItems[category]?.count ?? 0
                    if itemsCount > 0 {
                        Text("\(itemsCount) items • \(ByteCountFormatter.string(fromByteCount: size, countStyle: .file))")
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                    } else if category == .custom && !model.customFolderPath.isEmpty {
                        Text("Ready to scan")
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                    } else {
                        Text("Not scanned yet")
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(.secondary.opacity(0.4))
            }
            .padding(14)
            .background(Color.primary.opacity(isHovered ? 0.04 : 0.015))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isHovered ? iconColor.opacity(0.3) : Color.primary.opacity(0.03), lineWidth: 1.5)
            )
            .scaleEffect(isHovered ? 1.015 : 1.0)
            .animation(.spring(response: 0.25, dampingFraction: 0.75), value: isHovered)
        }
        .buttonStyle(PlainButtonStyle())
        .onHover { hover in
            isHovered = hover
        }
    }
}

// MARK: - Category Header View
struct CategoryHeaderView: View {
    @ObservedObject var model: AppModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(model.selectedCategory.rawValue)
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                    
                    if model.selectedCategory == .custom {
                        if model.customFolderPath.isEmpty {
                            Text("Select any folder to scan all standard & hidden files.")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        } else {
                            Text(model.customFolderPath)
                                .font(.system(size: 11, design: .monospaced))
                                .foregroundColor(.secondary)
                                .lineLimit(1)
                        }
                    } else {
                        let paths = Scanner.shared.getPaths(for: model.selectedCategory)
                        let pathsStr = paths.map { $0.path.replacingOccurrences(of: NSHomeDirectory(), with: "~") }.joined(separator: ", ")
                        Text(pathsStr)
                            .font(.system(size: 11, design: .monospaced))
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                }
                
                Spacer()
                
                // Scan / Rescan Trigger
                Button(action: {
                    if model.selectedCategory == .custom {
                        model.selectAndScanCustomFolder()
                    } else {
                        model.scanCategory(model.selectedCategory)
                    }
                }) {
                    HStack {
                        Image(systemName: model.selectedCategory == .custom && model.customFolderPath.isEmpty ? "folder" : "arrow.clockwise")
                        Text(model.selectedCategory == .custom && model.customFolderPath.isEmpty ? "Select Folder" : "Rescan")
                    }
                }
                .buttonStyle(.bordered)
                .disabled(model.isScanning || model.isCleaning)
            }
            
            // Stats & Cleaning options
            let itemCount = model.categoryItems[model.selectedCategory]?.count ?? 0
            if itemCount > 0 {
                HStack(spacing: 24) {
                    // Size Stat
                    let selSize = model.totalSelectedSize(for: model.selectedCategory)
                    let totSize = model.totalScannedSize(for: model.selectedCategory)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Selected Size")
                            .font(.system(size: 10))
                            .foregroundColor(.secondary)
                        Text("\(ByteCountFormatter.string(fromByteCount: selSize, countStyle: .file)) of \(ByteCountFormatter.string(fromByteCount: totSize, countStyle: .file))")
                            .font(.system(size: 14, weight: .bold, design: .monospaced))
                    }
                    
                    // Options
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Cleanup Method")
                            .font(.system(size: 10))
                            .foregroundColor(.secondary)
                        
                        Picker("", selection: $model.deletePermanently) {
                            Text("Move to Trash").tag(false)
                            Text("Delete Permanently").tag(true)
                        }
                        .pickerStyle(SegmentedPickerStyle())
                        .frame(width: 250)
                    }
                    
                    Spacer()
                    
                    // Action Buttons
                    Button(action: {
                        model.cleanSelected()
                    }) {
                        HStack {
                            Image(systemName: "trash.fill")
                            Text("Clean \(ByteCountFormatter.string(fromByteCount: selSize, countStyle: .file))")
                                .fontWeight(.semibold)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.red)
                    .disabled(selSize == 0 || model.isCleaning)
                }
                .padding(.vertical, 8)
                .padding(.horizontal, 12)
                .background(Color.primary.opacity(0.03))
                .cornerRadius(8)
                
                // Advanced Filters satisfying "select to delete all hidden and all files"
                HStack(spacing: 8) {
                    Text("Select:")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(.secondary)
                    
                    Button("All") {
                        model.selectAll(for: model.selectedCategory, selected: true)
                    }
                    .buttonStyle(.plain)
                    .foregroundColor(.blue)
                    .font(.system(size: 11))
                    
                    Text("|").foregroundColor(.secondary).font(.system(size: 11))
                    
                    Button("None") {
                        model.selectAll(for: model.selectedCategory, selected: false)
                    }
                    .buttonStyle(.plain)
                    .foregroundColor(.blue)
                    .font(.system(size: 11))
                    
                    Text("|").foregroundColor(.secondary).font(.system(size: 11))
                    
                    Button("Hidden Files") {
                        model.selectHiddenOnly(for: model.selectedCategory, selected: true)
                    }
                    .buttonStyle(.plain)
                    .foregroundColor(.blue)
                    .font(.system(size: 11))
                    
                    Text("|").foregroundColor(.secondary).font(.system(size: 11))
                    
                    Button("Visible Files") {
                        model.selectVisibleOnly(for: model.selectedCategory, selected: true)
                    }
                    .buttonStyle(.plain)
                    .foregroundColor(.blue)
                    .font(.system(size: 11))
                }
            }
        }
        .padding(20)
    }
}

// MARK: - Files List View
struct FileListView: View {
    @ObservedObject var model: AppModel
    
    var body: some View {
        VStack {
            let items = model.categoryItems[model.selectedCategory] ?? []
            
            if model.isScanning {
                VStack(spacing: 12) {
                    ProgressView()
                    Text("Scanning files... Please wait")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if model.selectedCategory == .custom && model.customFolderPath.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "folder.badge.plus")
                        .font(.system(size: 48))
                        .foregroundColor(.blue)
                        .opacity(0.8)
                    
                    Text("No Folder Selected")
                        .font(.system(size: 16, weight: .semibold))
                    
                    Text("Select a folder (e.g. downloads, code projects) to scan for caches, large files, and hidden files.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: 360)
                    
                    Button("Choose Folder...") {
                        model.selectAndScanCustomFolder()
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if items.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 36))
                        .foregroundColor(.green)
                    
                    Text("Clean & Tidy!")
                        .font(.headline)
                    
                    Text("No files detected in this category.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                // Table of Cleanable Items
                List {
                    // Header row
                    HStack {
                        Text("Name")
                            .font(.system(size: 10, weight: .bold))
                        Spacer()
                        Text("Size")
                            .font(.system(size: 10, weight: .bold))
                            .frame(width: 80, alignment: .trailing)
                    }
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    
                    Divider()
                    
                    ForEach(items) { item in
                        HStack(spacing: 10) {
                            // Checkbox
                            Toggle("", isOn: Binding(
                                get: { item.isSelected },
                                set: { _ in model.toggleItemSelection(category: model.selectedCategory, itemId: item.id) }
                            ))
                            .toggleStyle(CheckboxToggleStyle())
                            .labelsHidden()
                            
                            // Type Icon
                            Image(systemName: item.isDirectory ? "folder" : "doc")
                                .foregroundColor(item.isDirectory ? .blue : .secondary)
                                .font(.system(size: 12))
                            
                            // Name & Detail Path
                            VStack(alignment: .leading, spacing: 2) {
                                HStack(spacing: 6) {
                                    Text(item.name)
                                        .font(.system(size: 12, weight: .medium))
                                        .lineLimit(1)
                                    
                                    if item.isHidden {
                                        Text("HIDDEN")
                                            .font(.system(size: 8, weight: .bold))
                                            .foregroundColor(.purple)
                                            .padding(.horizontal, 4)
                                            .padding(.vertical, 1)
                                            .background(Color.purple.opacity(0.12))
                                            .cornerRadius(4)
                                    }
                                }
                                
                                Text(item.id)
                                    .font(.system(size: 9, design: .monospaced))
                                    .foregroundColor(.secondary)
                                    .lineLimit(1)
                            }
                            
                            Spacer()
                            
                            // Size label
                            Text(item.formattedSize)
                                .font(.system(size: 11, weight: .medium, design: .monospaced))
                                .foregroundColor(.primary)
                                .frame(width: 80, alignment: .trailing)
                        }
                        .padding(.vertical, 4)
                        .padding(.horizontal, 8)
                        .background(item.isSelected ? Color.blue.opacity(0.04) : Color.clear)
                        .cornerRadius(6)
                    }
                }
                .listStyle(PlainListStyle())
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Console Log Drawer View
struct ConsoleDrawer: View {
    @ObservedObject var model: AppModel
    @Binding var isExpanded: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            // Header Toggle
            Button(action: {
                withAnimation {
                    isExpanded.toggle()
                }
            }) {
                HStack {
                    Image(systemName: "terminal")
                        .font(.system(size: 12))
                    Text("Process Console Log (\(model.logs.count) entries)")
                        .font(.system(size: 11, weight: .semibold))
                    
                    Spacer()
                    
                    Image(systemName: isExpanded ? "chevron.down" : "chevron.up")
                        .font(.system(size: 10))
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Color.primary.opacity(0.04))
            }
            .buttonStyle(PlainButtonStyle())
            
            if isExpanded {
                ScrollViewReader { proxy in
                    ScrollView {
                        VStack(alignment: .leading, spacing: 4) {
                            if model.logs.isEmpty {
                                Text("Console idle. Scan or clean files to see logs.")
                                    .font(.system(size: 11, design: .monospaced))
                                    .foregroundColor(.secondary)
                            } else {
                                ForEach(0..<model.logs.count, id: \.self) { index in
                                    Text(model.logs[index])
                                        .font(.system(size: 10, design: .monospaced))
                                        .foregroundColor(model.logs[index].contains("Failed") ? .red : (model.logs[index].contains("complete") ? .green : .primary))
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .id(index)
                                }
                            }
                        }
                        .padding(12)
                    }
                    .frame(height: 100)
                    .background(Color.black.opacity(0.85))
                    .foregroundColor(.green)
                    .onChange(of: model.logs.count) { _ in
                        if !model.logs.isEmpty {
                            proxy.scrollTo(model.logs.count - 1, anchor: .bottom)
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Clean Success View
struct CleanSuccessView: View {
    @ObservedObject var model: AppModel
    
    var body: some View {
        VStack(spacing: 20) {
            Spacer()
            
            ZStack {
                Circle()
                    .fill(Color.green.opacity(0.1))
                    .frame(width: 120, height: 120)
                
                Circle()
                    .stroke(Color.green, lineWidth: 4)
                    .frame(width: 120, height: 120)
                    .shadow(color: .green.opacity(0.4), radius: 10)
                
                Image(systemName: "checkmark")
                    .font(.system(size: 48, weight: .bold))
                    .foregroundColor(.green)
            }
            
            VStack(spacing: 8) {
                Text("System Cleaned!")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)
                
                Text("Successfully cleared cache and select files.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            HStack(spacing: 40) {
                VStack(spacing: 4) {
                    Text("Space Freed")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(ByteCountFormatter.string(fromByteCount: model.cleanedBytes, countStyle: .file))
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundColor(.blue)
                }
                
                Divider()
                    .frame(height: 40)
                
                VStack(spacing: 4) {
                    Text("Items Removed")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("\(model.cleanedItemsCount)")
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundColor(.blue)
                }
            }
            .padding()
            .background(Color.primary.opacity(0.03))
            .cornerRadius(12)
            
            Button("Back to Dashboard") {
                model.showCleanSuccess = false
                model.selectedCategory = .dashboard
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
