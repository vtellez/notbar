import AppKit
import ApplicationServices

/// Una app del Dock que muestra un badge en su icono.
struct BadgedApp: Equatable {
    let name: String
    let label: String
    let url: URL?
}

/// Lee los badges de los iconos del Dock mediante la API de Accesibilidad.
/// Cada icono de app del Dock es un elemento AXApplicationDockItem y, cuando
/// tiene badge, expone su texto en el atributo "AXStatusLabel".
@MainActor
enum DockBadgeReader {
    static var isTrusted: Bool { AXIsProcessTrusted() }

    /// Pide el permiso de Accesibilidad mostrando el diálogo del sistema.
    static func requestPermission() {
        let key = kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String
        _ = AXIsProcessTrustedWithOptions([key: true] as CFDictionary)
    }

    static func read() -> [BadgedApp] {
        guard isTrusted,
              let dock = NSRunningApplication.runningApplications(withBundleIdentifier: "com.apple.dock").first
        else { return [] }

        let dockElement = AXUIElementCreateApplication(dock.processIdentifier)
        var result: [BadgedApp] = []
        for list in children(of: dockElement) where string(list, kAXRoleAttribute) == kAXListRole {
            for item in children(of: list) where string(item, kAXSubroleAttribute) == "AXApplicationDockItem" {
                guard let label = string(item, "AXStatusLabel"), !label.isEmpty else { continue }
                result.append(BadgedApp(
                    name: string(item, kAXTitleAttribute) ?? "App",
                    label: label,
                    url: url(item, kAXURLAttribute)
                ))
            }
        }
        return result
    }

    private static func value(_ element: AXUIElement, _ attribute: String) -> CFTypeRef? {
        var value: CFTypeRef?
        guard AXUIElementCopyAttributeValue(element, attribute as CFString, &value) == .success else { return nil }
        return value
    }

    private static func children(of element: AXUIElement) -> [AXUIElement] {
        value(element, kAXChildrenAttribute) as? [AXUIElement] ?? []
    }

    private static func string(_ element: AXUIElement, _ attribute: String) -> String? {
        value(element, attribute) as? String
    }

    private static func url(_ element: AXUIElement, _ attribute: String) -> URL? {
        value(element, attribute) as? URL
    }
}
