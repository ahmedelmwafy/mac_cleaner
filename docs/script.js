// MacCleaner Interactive Simulator Logic

document.addEventListener('DOMContentLoaded', () => {
    // Simulated category items data
    let categoriesData = {
        userCaches: {
            name: "User Caches",
            path: "~/Library/Caches",
            size: 1200000000, // 1.2 GB
            items: [
                { id: 'uc1', name: 'Google Chrome/Default/Cache', size: 450000000, isSelected: true, isHidden: false },
                { id: 'uc2', name: 'com.apple.Safari/Cache.db', size: 340000000, isSelected: true, isHidden: false },
                { id: 'uc3', name: 'com.spotify.client/Storage', size: 210000000, isSelected: true, isHidden: false },
                { id: 'uc4', name: 'com.figma.Desktop/Caches', size: 80000000, isSelected: true, isHidden: false },
                { id: 'uc5', name: '.DS_Store', size: 12000000, isSelected: true, isHidden: true },
                { id: 'uc6', name: 'com.apple.iTunes/SubscriptionPlayCache', size: 108000000, isSelected: true, isHidden: false }
            ]
        },
        devProjects: {
            name: "Project Builds",
            path: "Developer Project Directories",
            size: 14200000000, // 14.2 GB
            items: [
                { id: 'dp1', name: '[flutter_weather_app] Flutter Build (build/)', size: 4800000000, isSelected: true, isHidden: false },
                { id: 'dp2', name: '[nextjs_portfolio] Node Modules (node_modules/)', size: 5200000000, isSelected: true, isHidden: false },
                { id: 'dp3', name: '[react_native_chat] Node Modules (node_modules/)', size: 3400000000, isSelected: true, isHidden: false },
                { id: 'dp4', name: '[flutter_weather_app] Flutter Dart Tool (.dart_tool/)', size: 320000000, isSelected: true, isHidden: true },
                { id: 'dp5', name: '[ios_runner] CocoaPods (Pods/)', size: 480000000, isSelected: true, isHidden: false }
            ]
        },
        xcodeJunk: {
            name: "Xcode DerivedData",
            path: "~/Library/Developer/Xcode/DerivedData",
            size: 8400000000, // 8.4 GB
            items: [
                { id: 'xd1', name: 'MacCleaner-dhgfyrjhdghf/.../Build', size: 3200000000, isSelected: true, isHidden: false },
                { id: 'xd2', name: 'Runner-fjhgurygfhjd/.../Index', size: 2400000000, isSelected: true, isHidden: false },
                { id: 'xd3', name: 'WeatherApp-jhguryhgf/.../Logs', size: 1800000000, isSelected: true, isHidden: false },
                { id: 'xd4', name: 'ChatApp-fhguryfhd/.../Build', size: 1000000000, isSelected: true, isHidden: false }
            ]
        },
        gradleCache: {
            name: "Gradle Cache",
            path: "~/.gradle/caches",
            size: 3100000000, // 3.1 GB
            items: [
                { id: 'gc1', name: 'modules-2/files-2.1', size: 1800000000, isSelected: true, isHidden: false },
                { id: 'gc2', name: 'transforms-3/files', size: 920000000, isSelected: true, isHidden: false },
                { id: 'gc3', name: 'jars-9/classes.jar', size: 380000000, isSelected: true, isHidden: false },
                { id: 'gc4', name: '.lock', size: 100000, isSelected: true, isHidden: true }
            ]
        },
        androidCache: {
            name: "Android Cache",
            path: "~/.android/cache",
            size: 2400000000, // 2.4 GB
            items: [
                { id: 'ac1', name: 'emulator-caches/temp_assets', size: 1400000000, isSelected: true, isHidden: false },
                { id: 'ac2', name: 'Google/AndroidStudio2024.1/caches', size: 1000000000, isSelected: true, isHidden: false }
            ]
        },
        trash: {
            name: "System Trash",
            path: "~/.Trash",
            size: 450000000, // 450 MB
            items: [
                { id: 'tr1', name: 'Xcode_15_beta.dmg', size: 350000000, isSelected: true, isHidden: false },
                { id: 'tr2', name: 'old_backup.zip', size: 80000000, isSelected: true, isHidden: false },
                { id: 'tr3', name: 'Screenshot_2026.png', size: 20000000, isSelected: true, isHidden: false }
            ]
        }
    };

    // UI State variables
    let currentCategory = 'dashboard';
    let isScanning = false;
    let isCleaning = false;
    let consoleLogs = [];
    let isConsoleExpanded = false;

    // DOM Elements Cache
    const sidebarItems = document.querySelectorAll('.sidebar-item');
    const viewDashboard = document.getElementById('view-dashboard');
    const viewDetails = document.getElementById('view-details');
    const viewSuccess = document.getElementById('view-success');
    
    // Dashboard elements
    const gaugeSizeLabel = document.getElementById('dashboard-cleanable-size');
    const ringFill = document.getElementById('dashboard-ring-fill');
    const btnScan = document.getElementById('sim-btn-scan');
    const btnClean = document.getElementById('sim-btn-clean');
    const dashCards = document.querySelectorAll('.dash-card');

    // Details panel elements
    const detailsTitle = document.getElementById('details-view-title');
    const detailsPath = document.getElementById('details-view-path');
    const detailsList = document.getElementById('sim-details-list');
    
    // Filter buttons
    const filterAll = document.getElementById('filter-all');
    const filterNone = document.getElementById('filter-none');
    const filterHidden = document.getElementById('filter-hidden');
    const filterVisible = document.getElementById('filter-visible');

    // Success screen elements
    const successSize = document.getElementById('success-reclaimed-size');
    const successItems = document.getElementById('success-reclaimed-items');
    const successBackBtn = document.getElementById('success-back-btn');

    // Console elements
    const consoleHeaderBtn = document.getElementById('console-header-btn');
    const consoleBodyLogs = document.getElementById('console-body-logs');
    const consoleArrow = consoleHeaderBtn.querySelector('.console-arrow');
    
    // Control panel buttons
    const ctrlScanAll = document.getElementById('ctrl-scan-all');
    const ctrlCleanSelected = document.getElementById('ctrl-clean-selected');
    const ctrlCustomScan = document.getElementById('ctrl-custom-scan');

    // Mobile nav elements
    const mobileMenuBtn = document.getElementById('mobile-menu-btn');
    const mobileOverlay = document.getElementById('mobile-overlay');

    // ==========================================
    // Core Simulator Logic
    // ==========================================

    // Initialize UI Sizes
    updateBadgeSizes();
    updateDashboardRing();

    // Updates badge numbers in sidebar and dashboard cards
    function updateBadgeSizes() {
        let totalJunkSize = 0;
        
        Object.keys(categoriesData).forEach(key => {
            const cat = categoriesData[key];
            const catSize = cat.items.reduce((acc, item) => acc + (item.isSelected ? item.size : 0), 0);
            totalJunkSize += catSize;
            
            // Sidebar badges
            const badge = document.getElementById(`badge-${key}`);
            if (badge) {
                badge.textContent = formatBytes(catSize);
                badge.style.display = catSize > 0 ? 'inline-block' : 'none';
            }
            
            // Dashboard cards
            const cardSizeLabel = document.getElementById(`card-size-${key}`);
            if (cardSizeLabel) {
                cardSizeLabel.textContent = formatBytes(catSize);
            }
        });
        
        gaugeSizeLabel.textContent = formatBytes(totalJunkSize);
    }

    // Updates Dashboard ring trim / fill ratio
    function updateDashboardRing() {
        let total = 0;
        let selected = 0;
        
        Object.keys(categoriesData).forEach(key => {
            categoriesData[key].items.forEach(item => {
                total += item.size;
                if (item.isSelected) {
                    selected += item.size;
                }
            });
        });
        
        const ratio = total > 0 ? (selected / total) : 0;
        const circumference = 2 * Math.PI * 40; // r=40
        const strokeDashOffset = circumference - (ratio * circumference);
        
        ringFill.style.strokeDasharray = circumference;
        ringFill.style.strokeDashoffset = strokeDashOffset;
    }

    // Sidebar navigation handler
    function navigateToCategory(targetCategory) {
        if (isScanning || isCleaning) return;
        
        currentCategory = targetCategory;
        
        // Update sidebar visual active states
        sidebarItems.forEach(item => {
            if (item.dataset.target === targetCategory) {
                item.classList.add('active');
            } else {
                item.classList.remove('active');
            }
        });
        
        // Hide all views
        viewDashboard.classList.remove('active');
        viewDetails.classList.remove('active');
        viewSuccess.classList.remove('active');
        
        if (targetCategory === 'dashboard') {
            viewDashboard.classList.add('active');
        } else {
            viewDetails.classList.add('active');
            renderDetailsList(targetCategory);
        }
    }

    // Renders the checklist in detailed view
    function renderDetailsList(catKey) {
        const cat = categoriesData[catKey];
        detailsTitle.textContent = cat.name;
        detailsPath.textContent = cat.path;
        
        detailsList.innerHTML = '';
        
        if (cat.items.length === 0) {
            detailsList.innerHTML = `<li class="details-empty">Category is empty</li>`;
            return;
        }
        
        cat.items.forEach(item => {
            const li = document.createElement('li');
            li.className = `details-item ${item.isSelected ? 'selected' : ''}`;
            
            li.innerHTML = `
                <div class="details-item-main">
                    <input type="checkbox" class="details-checkbox" ${item.isSelected ? 'checked' : ''}>
                    <div class="details-item-info">
                        <div class="details-item-name font-mono">
                            ${item.name}
                            ${item.isHidden ? `<span class="hidden-badge">HIDDEN</span>` : ''}
                        </div>
                    </div>
                </div>
                <div class="details-item-size font-mono">${formatBytes(item.size)}</div>
            `;
            
            // Checkbox click toggle selection
            const checkbox = li.querySelector('.details-checkbox');
            checkbox.addEventListener('change', () => {
                item.isSelected = checkbox.checked;
                li.classList.toggle('selected', item.isSelected);
                updateBadgeSizes();
                updateDashboardRing();
            });
            
            li.addEventListener('click', (e) => {
                if (e.target.className !== 'details-checkbox') {
                    checkbox.checked = !checkbox.checked;
                    item.isSelected = checkbox.checked;
                    li.classList.toggle('selected', item.isSelected);
                    updateBadgeSizes();
                    updateDashboardRing();
                }
            });
            
            detailsList.appendChild(li);
        });
    }

    // ==========================================
    // Real-time Console Logging Simulator
    // ==========================================

    function appendLog(message, type = 'normal') {
        const line = document.createElement('div');
        const timestamp = new Date().toLocaleTimeString();
        line.className = `console-line ${type}`;
        line.innerHTML = `<span class="console-timestamp">[${timestamp}]</span> ${message}`;
        
        if (consoleLogs.length === 0) {
            consoleBodyLogs.innerHTML = '';
        }
        
        consoleLogs.push(line);
        consoleBodyLogs.appendChild(line);
        
        // Auto scroll to bottom
        consoleBodyLogs.scrollTop = consoleBodyLogs.scrollHeight;
    }

    function toggleConsole() {
        isConsoleExpanded = !isConsoleExpanded;
        const consoleDrawer = document.querySelector('.app-console-drawer');
        consoleDrawer.classList.toggle('active', isConsoleExpanded);
        consoleArrow.textContent = isConsoleExpanded ? '▼' : '▲';
    }

    // ==========================================
    // System Scan Actions (Simulations)
    // ==========================================

    function runSimulationScan() {
        if (isScanning || isCleaning) return;
        
        isScanning = true;
        navigateToCategory('dashboard');
        
        // Expand console automatically
        if (!isConsoleExpanded) toggleConsole();
        
        consoleLogs = [];
        appendLog('Initializing deep system scanning parameters...', 'muted');
        
        let scanSteps = [
            { text: 'Scanning user directories for app caches...', time: 600 },
            { text: 'Found Safari cache entries (340 MB)...', time: 1000 },
            { text: 'Found Google Chrome cache databases (450 MB)...', time: 1400 },
            { text: 'Traversing developer workspace paths...', time: 1900 },
            { text: 'Detected Flutter pubspec descriptors in Desktop/projects...', time: 2400 },
            { text: 'Found build directory in flutter_weather_app (4.8 GB)...', time: 2800 },
            { text: 'Scanning Xcode DerivedData folder...', time: 3300 },
            { text: 'Found DerivedData Runner binaries (2.4 GB)...', time: 3700 },
            { text: 'Reading Gradle dependencies in user folder...', time: 4200 },
            { text: 'Android studio logs collected (2.4 GB)...', time: 4600 },
            { text: 'System scan complete. Identified 29.7 GB of safe-cleanable items.', type: 'green', time: 5000 }
        ];

        // Animate the circular fill during scan
        ringFill.style.transition = 'stroke-dashoffset 5s linear';
        ringFill.style.strokeDashoffset = '0';
        
        scanSteps.forEach(step => {
            setTimeout(() => {
                appendLog(step.text, step.type || 'normal');
            }, step.time);
        });

        // Terminate scanning state
        setTimeout(() => {
            isScanning = false;
            ringFill.style.transition = 'stroke-dashoffset 0.3s cubic-bezier(0.16, 1, 0.3, 1)';
            updateDashboardRing();
            updateBadgeSizes();
        }, 5100);
    }

    function runSimulationClean() {
        if (isScanning || isCleaning) return;
        
        // Check if there are elements selected
        let totalToClean = 0;
        let itemsCount = 0;
        
        Object.keys(categoriesData).forEach(key => {
            categoriesData[key].items.forEach(item => {
                if (item.isSelected) {
                    totalToClean += item.size;
                    itemsCount++;
                }
            });
        });
        
        if (itemsCount === 0) {
            alert('No items selected for cleaning! Navigate to a category and check some boxes.');
            return;
        }
        
        isCleaning = true;
        if (!isConsoleExpanded) toggleConsole();
        
        appendLog(`Preparing safe delete operations for ${itemsCount} items (${formatBytes(totalToClean)})...`, 'muted');
        
        let cleanSteps = [
            { text: 'Shutting down safe file-system hooks...', time: 500 },
            { text: 'Cleaning user cache databases...', time: 1000 },
            { text: 'Deleted cache file: Google Chrome/Default/Cache', time: 1300 },
            { text: 'Cleaning developer build outputs...', time: 1800 },
            { text: 'Removing local Flutter build caches...', time: 2200 },
            { text: 'Purging Xcode DerivedData folders...', time: 2600 },
            { text: 'Emptying Android caches & logs...', time: 3000 },
            { text: 'Clean operations completed successfully.', type: 'green', time: 3500 }
        ];
        
        cleanSteps.forEach(step => {
            setTimeout(() => {
                appendLog(step.text, step.type || 'normal');
            }, step.time);
        });
        
        setTimeout(() => {
            // Reclaim sizes (remove selected items from list)
            Object.keys(categoriesData).forEach(key => {
                categoriesData[key].items = categoriesData[key].items.filter(item => !item.isSelected);
            });
            
            isCleaning = false;
            
            // Show Success view
            successSize.textContent = formatBytes(totalToClean);
            successItems.textContent = itemsCount;
            
            // Update models
            updateBadgeSizes();
            updateDashboardRing();
            
            // Activate success view
            viewDashboard.classList.remove('active');
            viewDetails.classList.remove('active');
            viewSuccess.classList.add('active');
        }, 3650);
    }

    // ==========================================
    // Event Listeners Configuration
    // ==========================================

    // Sidebar navigation clicks
    sidebarItems.forEach(item => {
        item.addEventListener('click', () => {
            navigateToCategory(item.dataset.target);
        });
    });

    // Dashboard grid cards navigation
    dashCards.forEach(card => {
        card.addEventListener('click', () => {
            navigateToCategory(card.dataset.nav);
        });
    });

    // Internal window button clicks
    btnScan.addEventListener('click', runSimulationScan);
    btnClean.addEventListener('click', runSimulationClean);
    successBackBtn.addEventListener('click', () => navigateToCategory('dashboard'));

    // Console toggle click
    consoleHeaderBtn.addEventListener('click', toggleConsole);

    // Filter operations (checks/unchecks checkboxes in current detailed list)
    filterAll.addEventListener('click', () => {
        if (currentCategory === 'dashboard') return;
        categoriesData[currentCategory].items.forEach(i => i.isSelected = true);
        renderDetailsList(currentCategory);
        updateBadgeSizes();
        updateDashboardRing();
    });

    filterNone.addEventListener('click', () => {
        if (currentCategory === 'dashboard') return;
        categoriesData[currentCategory].items.forEach(i => i.isSelected = false);
        renderDetailsList(currentCategory);
        updateBadgeSizes();
        updateDashboardRing();
    });

    filterHidden.addEventListener('click', () => {
        if (currentCategory === 'dashboard') return;
        categoriesData[currentCategory].items.forEach(i => {
            if (i.isHidden) i.isSelected = true;
            else i.isSelected = false;
        });
        renderDetailsList(currentCategory);
        updateBadgeSizes();
        updateDashboardRing();
    });

    filterVisible.addEventListener('click', () => {
        if (currentCategory === 'dashboard') return;
        categoriesData[currentCategory].items.forEach(i => {
            if (!i.isHidden) i.isSelected = true;
            else i.isSelected = false;
        });
        renderDetailsList(currentCategory);
        updateBadgeSizes();
        updateDashboardRing();
    });

    // Simulation control panel triggers
    ctrlScanAll.addEventListener('click', runSimulationScan);
    ctrlCleanSelected.addEventListener('click', runSimulationClean);
    
    ctrlCustomScan.addEventListener('click', () => {
        if (isScanning || isCleaning) return;
        alert('Simulating Custom Folder Scanner! Selected folder: ~/Desktop/projects/flutter_app. Initializing recursive search including hidden files...');
        runSimulationScan();
    });

    // Mobile nav drawer clicks
    mobileMenuBtn.addEventListener('click', () => {
        mobileOverlay.classList.toggle('active');
        const bars = mobileMenuBtn.querySelectorAll('.bar');
        bars[0].style.transform = mobileOverlay.classList.contains('active') ? 'translateY(8px) rotate(45deg)' : 'none';
        bars[1].style.opacity = mobileOverlay.classList.contains('active') ? '0' : '1';
        bars[2].style.transform = mobileOverlay.classList.contains('active') ? 'translateY(-8px) rotate(-45deg)' : 'none';
    });

    mobileOverlay.querySelectorAll('.mobile-link').forEach(link => {
        link.addEventListener('click', () => {
            mobileOverlay.classList.remove('active');
            const bars = mobileMenuBtn.querySelectorAll('.bar');
            bars[0].style.transform = 'none';
            bars[1].style.opacity = '1';
            bars[2].style.transform = 'none';
        });
    });

    // ==========================================
    // Helper utilities
    // ==========================================

    // Byte counter formatter
    function formatBytes(bytes) {
        if (bytes === 0) return '0 KB';
        const k = 1024;
        const dm = 1;
        const sizes = ['Bytes', 'KB', 'MB', 'GB', 'TB'];
        const i = Math.floor(Math.log(bytes) / Math.log(k));
        return parseFloat((bytes / Math.pow(k, i)).toFixed(dm)) + ' ' + sizes[i];
    }
});
