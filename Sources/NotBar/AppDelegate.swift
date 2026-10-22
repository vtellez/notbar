import AppKit

@main
@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate, NSMenuDelegate {
    // NSApplication guarda su delegate como referencia débil.
    private static var instance: AppDelegate?

    static func main() {
        let app = NSApplication.shared
        let delegate = AppDelegate()
        instance = delegate
        app.delegate = delegate
        app.run()
    }

    private let pollInterval: TimeInterval = 2
    private var statusItem: NSStatusItem!
    private var statusIcon: StatusIcon!
    private var timer: Timer?
    private var badgedApps: [BadgedApp] = []
    private var lastBadged: Bool?

    func applicationDidFinishLaunching(_ notification: Notification) {
        Settings.applyDockIconPolicy()
        NSApp.mainMenu = makeMainMenu()

        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        statusIcon = StatusIcon(button: statusItem.button!)
        let menu = NSMenu()
        menu.delegate = self
        statusItem.menu = menu

        if !DockBadgeReader.isTrusted {
            DockBadgeReader.requestPermission()
        }

        refresh()
        timer = Timer.scheduledTimer(timeInterval: pollInterval, target: self,
                                     selector: #selector(refresh), userInfo: nil, repeats: true)
    }

    // Al hacer clic en el icono del Dock (si está visible) abrimos el menú de la barra.
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        statusItem.button?.performClick(nil)
        return false
    }

    @objc private func refresh() {
        badgedApps = DockBadgeReader.read()
        let badged = !badgedApps.isEmpty
        guard badged != lastBadged else { return }
        lastBadged = badged
        updateIcon()
        statusItem.button?.toolTip = badged ? "Hay apps con notificaciones" : "Sin notificaciones"
    }

    // MARK: - Menú

    func menuNeedsUpdate(_ menu: NSMenu) {
        refresh()
        menu.removeAllItems()

        if !DockBadgeReader.isTrusted {
            let warning = NSMenuItem(title: "Falta el permiso de Accesibilidad", action: nil, keyEquivalent: "")
            warning.isEnabled = false
            menu.addItem(warning)
            menu.addItem(item("Conceder permiso de Accesibilidad…", #selector(openAccessibilitySettings)))
        } else if badgedApps.isEmpty {
            let empty = NSMenuItem(title: "Sin notificaciones", action: nil, keyEquivalent: "")
            empty.isEnabled = false
            menu.addItem(empty)
        } else {
            for app in badgedApps {
                let entry = item("\(app.name)  (\(app.label))", #selector(openApp(_:)))
                entry.representedObject = app.url
                if let url = app.url {
                    let icon = NSWorkspace.shared.icon(forFile: url.path)
                    icon.size = NSSize(width: 16, height: 16)
                    entry.image = icon
                }
                menu.addItem(entry)
            }
        }

        menu.addItem(.separator())

        let login = item("Abrir al iniciar sesión", #selector(toggleLaunchAtLogin))
        login.state = Settings.launchAtLogin ? .on : .off
        menu.addItem(login)

        let iconItem = NSMenuItem(title: "Icono de la barra", action: nil, keyEquivalent: "")
        let iconMenu = NSMenu()
        for (index, group) in MenuIcon.groups.enumerated() {
            if index > 0 { iconMenu.addItem(.separator()) }
            for icon in group {
                let option = item(icon.title, #selector(selectIcon(_:)))
                option.representedObject = icon.rawValue
                option.image = icon.menuImage
                option.state = icon == MenuIcon.current ? .on : .off
                iconMenu.addItem(option)
            }
        }
        iconItem.submenu = iconMenu
        menu.addItem(iconItem)

        let colorItem = NSMenuItem(title: "Color de notificación", action: nil, keyEquivalent: "")
        let colorMenu = NSMenu()
        for color in BadgeColor.allCases {
            let option = item(color.title, #selector(selectColor(_:)))
            option.representedObject = color.rawValue
            option.image = color.menuImage
            option.state = color == BadgeColor.current ? .on : .off
            colorMenu.addItem(option)
        }
        colorItem.submenu = colorMenu
        menu.addItem(colorItem)

        let dock = item("Ocultar icono del Dock", #selector(toggleDockIcon))
        dock.state = Settings.hideDockIcon ? .on : .off
        menu.addItem(dock)

        menu.addItem(.separator())
        menu.addItem(NSMenuItem(title: "Salir de NotBar", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))
    }

    private func item(_ title: String, _ action: Selector) -> NSMenuItem {
        let item = NSMenuItem(title: title, action: action, keyEquivalent: "")
        item.target = self
        return item
    }

    private func makeMainMenu() -> NSMenu {
        let main = NSMenu()
        let appItem = NSMenuItem()
        let appMenu = NSMenu()
        appMenu.addItem(NSMenuItem(title: "Salir de NotBar", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))
        appItem.submenu = appMenu
        main.addItem(appItem)
        return main
    }

    // MARK: - Acciones

    @objc private func openApp(_ sender: NSMenuItem) {
        guard let url = sender.representedObject as? URL else { return }
        NSWorkspace.shared.openApplication(at: url, configuration: NSWorkspace.OpenConfiguration())
    }

    @objc private func toggleLaunchAtLogin() {
        if let error = Settings.setLaunchAtLogin(!Settings.launchAtLogin) {
            let alert = NSAlert()
            alert.messageText = "No se pudo cambiar el arranque al iniciar sesión"
            alert.informativeText = "\(error)\n\nAsegúrate de ejecutar NotBar desde /Applications."
            NSApp.activate(ignoringOtherApps: true)
            alert.runModal()
        }
    }

    @objc private func selectIcon(_ sender: NSMenuItem) {
        guard let raw = sender.representedObject as? String, let icon = MenuIcon(rawValue: raw) else { return }
        MenuIcon.current = icon
        updateIcon()
    }

    @objc private func selectColor(_ sender: NSMenuItem) {
        guard let raw = sender.representedObject as? String, let color = BadgeColor(rawValue: raw) else { return }
        BadgeColor.current = color
        updateIcon()
    }

    private func updateIcon() {
        statusIcon.update(icon: MenuIcon.current, color: BadgeColor.current, badged: !badgedApps.isEmpty)
    }

    @objc private func toggleDockIcon() {
        Settings.hideDockIcon.toggle()
    }

    @objc private func openAccessibilitySettings() {
        DockBadgeReader.requestPermission()
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
            NSWorkspace.shared.open(url)
        }
    }
}
