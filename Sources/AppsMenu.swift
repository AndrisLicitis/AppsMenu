import Cocoa

struct AppInfo {
    let name: String
    let path: String
    let bundleID: String
    let category: String
}

private let categoryOrder = [
    "⭐ Favorites", "🌐 Internet", "💬 Communication", "💻 Development",
    "🎨 Graphics & Design", "🎬 Media", "📄 Office & Productivity",
    "🎮 Games", "📚 Education", "🔧 Utilities", "⚙️ System", "📦 Other Apps"
]

final class IconCache {
    private let cache = NSCache<NSString, NSImage>()

    init() {
        cache.countLimit = 200
        cache.totalCostLimit = 24 * 1024 * 1024
    }

    func icon(for path: String) -> NSImage {
        let key = path as NSString
        if let cached = cache.object(forKey: key) { return cached }

        let image = NSWorkspace.shared.icon(forFile: path)
        image.size = NSSize(width: 18, height: 18)
        cache.setObject(image, forKey: key, cost: 18 * 18 * 4)
        return image
    }

    func clear() {
        cache.removeAllObjects()
    }
}

final class SettingsWindowController: NSWindowController, NSTableViewDataSource, NSTableViewDelegate {
    private let tableView = NSTableView()
    private let categoryPopup = NSPopUpButton()
    private var apps: [AppInfo] = []
    private var overrides: [String: String] = [:]
    private let onSave: ([String: String]) -> Void

    init(onSave: @escaping ([String: String]) -> Void) {
        self.onSave = onSave

        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 650, height: 460),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )
        window.title = "AppsMenu Settings"
        window.minSize = NSSize(width: 520, height: 360)
        window.center()

        super.init(window: window)
        buildInterface()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func update(apps: [AppInfo], overrides: [String: String]) {
        self.apps = apps.sorted {
            $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending
        }
        self.overrides = overrides
        tableView.reloadData()

        if !self.apps.isEmpty {
            tableView.selectRowIndexes(IndexSet(integer: 0), byExtendingSelection: false)
            updatePopupForSelection()
        }
    }

    func show() {
        NSApp.activate(ignoringOtherApps: true)
        window?.makeKeyAndOrderFront(nil)
    }

    private func buildInterface() {
        guard let contentView = window?.contentView else { return }

        let explanation = NSTextField(wrappingLabelWithString:
            "Izvēlies programmu un kategoriju. Iestatījumi tiek saglabāti lokāli un saglabājas arī pēc AppsMenu pārinstalēšanas."
        )
        explanation.translatesAutoresizingMaskIntoConstraints = false

        let scrollView = NSScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.hasVerticalScroller = true
        scrollView.borderType = .bezelBorder

        let appColumn = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("app"))
        appColumn.title = "Programma"
        appColumn.width = 330

        let categoryColumn = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("category"))
        categoryColumn.title = "Kategorija"
        categoryColumn.width = 260

        tableView.addTableColumn(appColumn)
        tableView.addTableColumn(categoryColumn)
        tableView.headerView = NSTableHeaderView()
        tableView.rowHeight = 24
        tableView.usesAlternatingRowBackgroundColors = true
        tableView.allowsMultipleSelection = false
        tableView.delegate = self
        tableView.dataSource = self
        tableView.target = self
        tableView.action = #selector(selectionChanged)
        scrollView.documentView = tableView

        categoryPopup.translatesAutoresizingMaskIntoConstraints = false
        categoryPopup.addItems(withTitles: categoryOrder)

        let assignButton = NSButton(title: "Piešķirt kategoriju", target: self, action: #selector(assignCategory))
        assignButton.translatesAutoresizingMaskIntoConstraints = false
        assignButton.keyEquivalent = "\r"

        let automaticButton = NSButton(title: "Atjaunot automātisko", target: self, action: #selector(useAutomaticCategory))
        automaticButton.translatesAutoresizingMaskIntoConstraints = false

        let closeButton = NSButton(title: "Aizvērt", target: self, action: #selector(closeSettings))
        closeButton.translatesAutoresizingMaskIntoConstraints = false

        contentView.addSubview(explanation)
        contentView.addSubview(scrollView)
        contentView.addSubview(categoryPopup)
        contentView.addSubview(assignButton)
        contentView.addSubview(automaticButton)
        contentView.addSubview(closeButton)

        NSLayoutConstraint.activate([
            explanation.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 16),
            explanation.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            explanation.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),

            scrollView.topAnchor.constraint(equalTo: explanation.bottomAnchor, constant: 12),
            scrollView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            scrollView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            scrollView.bottomAnchor.constraint(equalTo: categoryPopup.topAnchor, constant: -14),

            categoryPopup.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            categoryPopup.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -16),
            categoryPopup.widthAnchor.constraint(greaterThanOrEqualToConstant: 190),

            assignButton.leadingAnchor.constraint(equalTo: categoryPopup.trailingAnchor, constant: 10),
            assignButton.centerYAnchor.constraint(equalTo: categoryPopup.centerYAnchor),

            automaticButton.leadingAnchor.constraint(equalTo: assignButton.trailingAnchor, constant: 10),
            automaticButton.centerYAnchor.constraint(equalTo: categoryPopup.centerYAnchor),

            closeButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            closeButton.centerYAnchor.constraint(equalTo: categoryPopup.centerYAnchor)
        ])
    }

    func numberOfRows(in tableView: NSTableView) -> Int {
        apps.count
    }

    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        guard row >= 0, row < apps.count, let tableColumn else { return nil }
        let app = apps[row]
        let identifier = tableColumn.identifier

        let cell = (tableView.makeView(withIdentifier: identifier, owner: self) as? NSTableCellView) ?? {
            let newCell = NSTableCellView()
            newCell.identifier = identifier
            let textField = NSTextField(labelWithString: "")
            textField.translatesAutoresizingMaskIntoConstraints = false
            textField.lineBreakMode = .byTruncatingTail
            newCell.textField = textField
            newCell.addSubview(textField)
            NSLayoutConstraint.activate([
                textField.leadingAnchor.constraint(equalTo: newCell.leadingAnchor, constant: 6),
                textField.trailingAnchor.constraint(equalTo: newCell.trailingAnchor, constant: -6),
                textField.centerYAnchor.constraint(equalTo: newCell.centerYAnchor)
            ])
            return newCell
        }()

        if identifier.rawValue == "app" {
            cell.textField?.stringValue = app.name
        } else {
            let custom = overrides[app.path]
            cell.textField?.stringValue = custom.map { "\($0)  • manuāli" } ?? app.category
        }
        return cell
    }

    func tableViewSelectionDidChange(_ notification: Notification) {
        updatePopupForSelection()
    }

    @objc private func selectionChanged() {
        updatePopupForSelection()
    }

    private func updatePopupForSelection() {
        let row = tableView.selectedRow
        guard row >= 0, row < apps.count else { return }
        let app = apps[row]
        let selectedCategory = overrides[app.path] ?? app.category
        categoryPopup.selectItem(withTitle: selectedCategory)
    }

    @objc private func assignCategory() {
        let row = tableView.selectedRow
        guard row >= 0, row < apps.count,
              let category = categoryPopup.selectedItem?.title else { return }

        overrides[apps[row].path] = category
        onSave(overrides)
        tableView.reloadData(forRowIndexes: IndexSet(integer: row), columnIndexes: IndexSet(integer: 1))
    }

    @objc private func useAutomaticCategory() {
        let row = tableView.selectedRow
        guard row >= 0, row < apps.count else { return }

        overrides.removeValue(forKey: apps[row].path)
        onSave(overrides)
        categoryPopup.selectItem(withTitle: apps[row].category)
        tableView.reloadData(forRowIndexes: IndexSet(integer: row), columnIndexes: IndexSet(integer: 1))
    }

    @objc private func closeSettings() {
        window?.close()
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate, NSMenuDelegate {
    private var statusItem: NSStatusItem!
    private let iconCache = IconCache()
    private let scanQueue = DispatchQueue(label: "lv.andris.appsmenu.scan", qos: .utility)
    private var apps: [AppInfo] = []
    private var isScanning = false
    private let finderPath = "/System/Library/CoreServices/Finder.app"
    private let overridesDefaultsKey = "categoryOverrides"
    private lazy var settingsWindow = SettingsWindowController { [weak self] overrides in
        self?.saveOverrides(overrides)
        self?.reloadApps(clearIcons: false)
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)

        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        statusItem.button?.title = "☰"
        statusItem.button?.toolTip = "AppsMenu"

        let menu = NSMenu()
        menu.delegate = self
        statusItem.menu = menu

        reloadApps(clearIcons: false)
    }

    func menuWillOpen(_ menu: NSMenu) {
        buildMenu(menu)
    }

    private func loadOverrides() -> [String: String] {
        UserDefaults.standard.dictionary(forKey: overridesDefaultsKey) as? [String: String] ?? [:]
    }

    private func saveOverrides(_ overrides: [String: String]) {
        UserDefaults.standard.set(overrides, forKey: overridesDefaultsKey)
    }

    private func roots() -> [URL] {
        [
            URL(fileURLWithPath: "/Applications", isDirectory: true),
            URL(fileURLWithPath: NSHomeDirectory() + "/Applications", isDirectory: true),
            URL(fileURLWithPath: "/System/Applications", isDirectory: true),
            URL(fileURLWithPath: "/System/Library/CoreServices/Applications", isDirectory: true)
        ]
    }

    private func shouldHide(name: String, path: String, bundleID: String) -> Bool {
        let n = name.lowercased()
        let p = path.lowercased()
        let b = bundleID.lowercased()

        if p.contains("/contents/") { return true }

        let blockedWords = [
            "helper", "renderer", "gpu", "plugin", "crashpad",
            "updater", "auto update", "autoupdate", "login item", "service"
        ]

        return blockedWords.contains { word in
            n.contains(word) || b.contains(word.replacingOccurrences(of: " ", with: ""))
        }
    }

    private func containsAny(_ text: String, _ words: [String]) -> Bool {
        words.contains { text.contains($0) }
    }

    private func automaticCategory(name: String, path: String, bundleID: String, plistCategory: String?) -> String {
        let n = name.lowercased()
        let b = bundleID.lowercased()
        let p = path.lowercased()

        if name == "Finder" || b == "com.apple.finder" { return "⭐ Favorites" }
        if containsAny(n, ["latvia-eid-pintool", "eid", "pin tool"]) { return "🔧 Utilities" }
        if containsAny(n, ["eparak", "edoc"]) { return "📄 Office & Productivity" }

        switch plistCategory ?? "" {
        case "public.app-category.developer-tools":
            return "💻 Development"
        case "public.app-category.graphics-design", "public.app-category.photography":
            return "🎨 Graphics & Design"
        case "public.app-category.music", "public.app-category.video", "public.app-category.entertainment":
            return "🎬 Media"
        case "public.app-category.social-networking":
            return "💬 Communication"
        case "public.app-category.business", "public.app-category.productivity":
            return "📄 Office & Productivity"
        case "public.app-category.games":
            return "🎮 Games"
        case "public.app-category.utilities":
            return "🔧 Utilities"
        case "public.app-category.education":
            return "📚 Education"
        default:
            break
        }

        let groups: [(category: String, terms: [String])] = [
            ("🌐 Internet", ["safari", "chrome", "firefox", "edge", "brave", "opera", "browser"]),
            ("💬 Communication", ["discord", "telegram", "whatsapp", "chatgpt", "messages", "facetime", "mail"]),
            ("💻 Development", ["xcode", "vscode", "visualstudiocode", "github", "docker", "terminal", "code"]),
            ("🎨 Graphics & Design", ["gimp", "inkscape", "photo", "paint", "preview"]),
            ("🎬 Media", ["vlc", "spotify", "music", "audacity", "garageband", "shotcut", "quicktime", "podcasts"]),
            ("📄 Office & Productivity", ["libreoffice", "pages", "numbers", "keynote", "textedit", "dictionary", "calendar", "notes", "reminders", "passwords"]),
            ("🎮 Games", ["chess", "steam", "game"]),
            ("🔧 Utilities", ["keka", "archive", "capture", "cog", "nap", "utility"])
        ]

        for group in groups where containsAny(n, group.terms) || containsAny(b, group.terms) {
            return group.category
        }

        let systemApps = [
            "activity monitor", "console", "disk utility", "system settings", "automator",
            "keychain access", "migration assistant", "screen sharing", "time machine"
        ]
        if p.contains("/system/") || systemApps.contains(n) { return "⚙️ System" }
        if n == "tv" { return "🎬 Media" }
        return "📦 Other Apps"
    }

    private func appInfo(path: String, overrides: [String: String]) -> AppInfo? {
        let url = URL(fileURLWithPath: path)
        let name = url.deletingPathExtension().lastPathComponent
        guard let bundle = Bundle(path: path) else { return nil }

        let bundleID = bundle.bundleIdentifier ?? ""
        if shouldHide(name: name, path: path, bundleID: bundleID) { return nil }

        let plistCategory = bundle.object(forInfoDictionaryKey: "LSApplicationCategoryType") as? String
        let automatic = automaticCategory(name: name, path: path, bundleID: bundleID, plistCategory: plistCategory)

        return AppInfo(
            name: name,
            path: path,
            bundleID: bundleID,
            category: overrides[path] ?? automatic
        )
    }

    private func scanApps() -> [AppInfo] {
        var result: [AppInfo] = []
        var seenPaths = Set<String>()
        var seenBundles = Set<String>()
        let overrides = loadOverrides()

        if FileManager.default.fileExists(atPath: finderPath),
           let finder = appInfo(path: finderPath, overrides: overrides) {
            result.append(finder)
            seenPaths.insert(finderPath)
            if !finder.bundleID.isEmpty { seenBundles.insert(finder.bundleID) }
        }

        let keys: [URLResourceKey] = [.isDirectoryKey, .isPackageKey]
        let options: FileManager.DirectoryEnumerationOptions = [.skipsHiddenFiles]

        for root in roots() {
            guard FileManager.default.fileExists(atPath: root.path),
                  let enumerator = FileManager.default.enumerator(
                    at: root,
                    includingPropertiesForKeys: keys,
                    options: options,
                    errorHandler: { _, _ in true }
                  ) else { continue }

            while let url = enumerator.nextObject() as? URL {
                guard url.pathExtension.lowercased() == "app" else { continue }
                enumerator.skipDescendants()

                let full = url.path
                if seenPaths.contains(full) { continue }
                guard let info = appInfo(path: full, overrides: overrides) else { continue }
                if !info.bundleID.isEmpty && seenBundles.contains(info.bundleID) { continue }

                seenPaths.insert(full)
                if !info.bundleID.isEmpty { seenBundles.insert(info.bundleID) }
                result.append(info)
            }
        }

        return result.sorted {
            $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending
        }
    }

    private func reloadApps(clearIcons: Bool) {
        guard !isScanning else { return }
        isScanning = true
        statusItem.button?.toolTip = "AppsMenu — refreshing…"

        scanQueue.async { [weak self] in
            guard let self else { return }
            let foundApps = self.scanApps()

            DispatchQueue.main.async { [weak self] in
                guard let self else { return }
                self.apps = foundApps
                self.isScanning = false
                self.statusItem.button?.toolTip = "AppsMenu — \(foundApps.count) apps"
                if clearIcons { self.iconCache.clear() }
                if let menu = self.statusItem.menu { self.buildMenu(menu) }
            }
        }
    }

    private func buildMenu(_ menu: NSMenu) {
        menu.removeAllItems()

        if apps.isEmpty {
            let loading = NSMenuItem(
                title: isScanning ? "Loading applications…" : "No applications found",
                action: nil,
                keyEquivalent: ""
            )
            loading.isEnabled = false
            menu.addItem(loading)
            menu.addItem(NSMenuItem.separator())
        } else {
            let grouped = Dictionary(grouping: apps, by: { $0.category })

            for group in categoryOrder {
                guard let groupApps = grouped[group], !groupApps.isEmpty else { continue }

                if group == "⭐ Favorites" {
                    for app in groupApps { menu.addItem(menuItem(for: app)) }
                    menu.addItem(NSMenuItem.separator())
                } else {
                    let groupItem = NSMenuItem(title: group, action: nil, keyEquivalent: "")
                    let subMenu = NSMenu()
                    for app in groupApps { subMenu.addItem(menuItem(for: app)) }
                    menu.addItem(groupItem)
                    menu.setSubmenu(subMenu, for: groupItem)
                }
            }
        }

        menu.addItem(NSMenuItem.separator())

        let settingsItem = NSMenuItem(title: "Settings…", action: #selector(openSettings), keyEquivalent: ",")
        settingsItem.target = self
        menu.addItem(settingsItem)

        let refreshItem = NSMenuItem(
            title: isScanning ? "Refreshing…" : "Refresh Apps List",
            action: #selector(refresh),
            keyEquivalent: "r"
        )
        refreshItem.target = self
        refreshItem.isEnabled = !isScanning
        menu.addItem(refreshItem)

        let quitItem = NSMenuItem(title: "Quit AppsMenu", action: #selector(quit), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)
    }

    private func menuItem(for app: AppInfo) -> NSMenuItem {
        let item = NSMenuItem(title: app.name, action: #selector(openApp(_:)), keyEquivalent: "")
        item.target = self
        item.representedObject = app.path
        item.image = iconCache.icon(for: app.path)
        return item
    }

    @objc private func openSettings() {
        settingsWindow.update(apps: apps, overrides: loadOverrides())
        settingsWindow.show()
    }

    @objc private func refresh() {
        reloadApps(clearIcons: true)
        if let menu = statusItem.menu { buildMenu(menu) }
    }

    @objc private func openApp(_ sender: NSMenuItem) {
        guard let path = sender.representedObject as? String else { return }
        NSWorkspace.shared.openApplication(
            at: URL(fileURLWithPath: path),
            configuration: NSWorkspace.OpenConfiguration()
        )
    }

    @objc private func quit() {
        NSApp.terminate(nil)
    }
}

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.run()
