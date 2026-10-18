import AppKit

/// Iconos disponibles para la barra de menús. Todos son SF Symbols rellenos,
/// así que se dibujan nítidos a cualquier resolución y siguen el estilo del sistema.
enum MenuIcon: String, CaseIterable {
    case app = "app.fill"
    case grid = "square.grid.2x2.fill"
    case tray = "tray.fill"
    case bubble = "bubble.left.fill"
    case envelope = "envelope.fill"
    case dot = "circle.fill"

    var title: String {
        switch self {
        case .app: return "App"
        case .grid: return "Cuadrícula"
        case .tray: return "Bandeja"
        case .bubble: return "Mensaje"
        case .envelope: return "Sobre"
        case .dot: return "Punto"
        }
    }

    private static let defaultsKey = "menuIcon"

    static var current: MenuIcon {
        get { UserDefaults.standard.string(forKey: defaultsKey).flatMap(MenuIcon.init(rawValue:)) ?? .grid }
        set { UserDefaults.standard.set(newValue.rawValue, forKey: defaultsKey) }
    }

    /// Imagen pequeña del símbolo para el submenú de selección.
    var menuImage: NSImage? {
        NSImage(systemSymbolName: rawValue, accessibilityDescription: title)?
            .withSymbolConfiguration(.init(pointSize: 13, weight: .regular))
    }
}

/// Pinta el icono de la barra: el símbolo como imagen plantilla (macOS lo adapta a
/// modo claro/oscuro y a la resolución) y, si hay notificaciones, un punto rojo
/// superpuesto como capa aparte, para no tener que componer imágenes a mano.
@MainActor
final class StatusIcon {
    private let button: NSStatusBarButton
    private let dot = NSView()
    private var dotX: NSLayoutConstraint?
    private var dotY: NSLayoutConstraint?
    private let symbolConfig = NSImage.SymbolConfiguration(pointSize: 15, weight: .regular)
    private let dotSize: CGFloat = 7

    init(button: NSStatusBarButton) {
        self.button = button
        dot.wantsLayer = true
        dot.layer?.backgroundColor = NSColor.systemRed.cgColor
        dot.layer?.cornerRadius = dotSize / 2
        dot.translatesAutoresizingMaskIntoConstraints = false
        dot.isHidden = true
        button.addSubview(dot)
        NSLayoutConstraint.activate([
            dot.widthAnchor.constraint(equalToConstant: dotSize),
            dot.heightAnchor.constraint(equalToConstant: dotSize),
        ])
    }

    func update(icon: MenuIcon, badged: Bool) {
        guard let symbol = NSImage(systemSymbolName: icon.rawValue, accessibilityDescription: "NotBar")?
            .withSymbolConfiguration(symbolConfig) else { return }

        if icon == .dot {
            // El propio círculo se vuelve rojo; no hace falta un punto encima.
            if badged, let red = symbol.withSymbolConfiguration(.init(paletteColors: [.systemRed])) {
                red.isTemplate = false
                button.image = red
            } else {
                symbol.isTemplate = true
                button.image = symbol
            }
            dot.isHidden = true
            return
        }

        symbol.isTemplate = true
        button.image = symbol

        // Coloca el punto en la esquina superior derecha del símbolo.
        dotX?.isActive = false
        dotY?.isActive = false
        let size = symbol.size
        dotX = dot.centerXAnchor.constraint(equalTo: button.centerXAnchor, constant: size.width / 2 - 1)
        dotY = dot.centerYAnchor.constraint(equalTo: button.centerYAnchor, constant: -(size.height / 2 - 1))
        dotX?.isActive = true
        dotY?.isActive = true
        dot.isHidden = !badged
    }
}
