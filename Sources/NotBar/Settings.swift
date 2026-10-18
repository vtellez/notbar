import AppKit
import ServiceManagement

@MainActor
enum Settings {
    private static let hideDockIconKey = "hideDockIcon"

    /// Por defecto el icono del Dock está oculto.
    static var hideDockIcon: Bool {
        get { UserDefaults.standard.object(forKey: hideDockIconKey) as? Bool ?? true }
        set {
            UserDefaults.standard.set(newValue, forKey: hideDockIconKey)
            applyDockIconPolicy()
        }
    }

    static func applyDockIconPolicy() {
        if hideDockIcon {
            NSApp.setActivationPolicy(.accessory)
        } else {
            NSApp.setActivationPolicy(.regular)
            NSApp.activate(ignoringOtherApps: true)
        }
    }

    static var launchAtLogin: Bool {
        SMAppService.mainApp.status == .enabled
    }

    /// Activa o desactiva el arranque al iniciar sesión. Devuelve un error legible si falla.
    static func setLaunchAtLogin(_ enabled: Bool) -> String? {
        let service = SMAppService.mainApp
        do {
            if enabled {
                try service.register()
            } else {
                try service.unregister()
            }
        } catch {
            return error.localizedDescription
        }
        if service.status == .requiresApproval {
            SMAppService.openSystemSettingsLoginItems()
        }
        return nil
    }
}
