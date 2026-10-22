import AppKit

/// Iconos disponibles para la barra de menús. Todos son SF Symbols rellenos,
/// así que se dibujan nítidos a cualquier resolución y siguen el estilo del sistema.
enum MenuIcon: String, CaseIterable {
    // Formas
    case dot = "circle.fill"
    case square = "square.fill"
    case diamond = "diamond.fill"
    case hexagon = "hexagon.fill"
    case triangle = "triangle.fill"
    case seal = "seal.fill"
    case star = "star.fill"
    case heart = "heart.fill"
    // Comunicación
    case bell = "bell.fill"
    case envelope = "envelope.fill"
    case bubble = "bubble.left.fill"
    case conversation = "bubble.left.and.bubble.right.fill"
    case phone = "phone.fill"
    case megaphone = "megaphone.fill"
    case tray = "tray.fill"
    // Otros
    case grid = "square.grid.2x2.fill"
    case app = "app.fill"
    case flag = "flag.fill"
    case bolt = "bolt.fill"
    case flame = "flame.fill"
    case tag = "tag.fill"
    case bookmark = "bookmark.fill"
    case lightbulb = "lightbulb.fill"
    case leaf = "leaf.fill"
    case pawprint = "pawprint.fill"

    /// Grupos en el orden en que aparecen en el submenú, separados por una línea.
    static let groups: [[MenuIcon]] = [
        [.dot, .square, .diamond, .hexagon, .triangle, .seal, .star, .heart],
        [.bell, .envelope, .bubble, .conversation, .phone, .megaphone, .tray],
        [.grid, .app, .flag, .bolt, .flame, .tag, .bookmark, .lightbulb, .leaf, .pawprint],
    ]

    var title: String {
        switch self {
        case .dot: return "Punto"
        case .square: return "Cuadrado"
        case .diamond: return "Rombo"
        case .hexagon: return "Hexágono"
        case .triangle: return "Triángulo"
        case .seal: return "Sello"
        case .star: return "Estrella"
        case .heart: return "Corazón"
        case .bell: return "Campana"
        case .envelope: return "Sobre"
        case .bubble: return "Mensaje"
        case .conversation: return "Conversación"
        case .phone: return "Teléfono"
        case .megaphone: return "Megáfono"
        case .tray: return "Bandeja"
        case .grid: return "Cuadrícula"
        case .app: return "App"
        case .flag: return "Bandera"
        case .bolt: return "Rayo"
        case .flame: return "Llama"
        case .tag: return "Etiqueta"
        case .bookmark: return "Marcador"
        case .lightbulb: return "Bombilla"
        case .leaf: return "Hoja"
        case .pawprint: return "Huella"
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

/// Color con el que se pinta el icono entero cuando hay notificaciones.
enum BadgeColor: String, CaseIterable {
    case red, orange, yellow, green, mint, teal, blue, indigo, purple, pink

    var title: String {
        switch self {
        case .red: return "Rojo"
        case .orange: return "Naranja"
        case .yellow: return "Amarillo"
        case .green: return "Verde"
        case .mint: return "Menta"
        case .teal: return "Turquesa"
        case .blue: return "Azul"
        case .indigo: return "Índigo"
        case .purple: return "Morado"
        case .pink: return "Rosa"
        }
    }

    var color: NSColor {
        switch self {
        case .red: return .systemRed
        case .orange: return .systemOrange
        case .yellow: return .systemYellow
        case .green: return .systemGreen
        case .mint: return .systemMint
        case .teal: return .systemTeal
        case .blue: return .systemBlue
        case .indigo: return .systemIndigo
        case .purple: return .systemPurple
        case .pink: return .systemPink
        }
    }

    private static let defaultsKey = "badgeColor"

    static var current: BadgeColor {
        get { UserDefaults.standard.string(forKey: defaultsKey).flatMap(BadgeColor.init(rawValue:)) ?? .red }
        set { UserDefaults.standard.set(newValue.rawValue, forKey: defaultsKey) }
    }

    /// Muestra circular del color para el submenú de selección.
    var menuImage: NSImage {
        let color = color
        let image = NSImage(size: NSSize(width: 12, height: 12), flipped: false) { rect in
            color.setFill()
            NSBezierPath(ovalIn: rect.insetBy(dx: 0.5, dy: 0.5)).fill()
            return true
        }
        image.accessibilityDescription = title
        return image
    }
}

/// Pinta el icono de la barra. Sin notificaciones es una imagen plantilla (macOS la
/// adapta a modo claro/oscuro); con notificaciones el símbolo entero se pinta del
/// color elegido.
@MainActor
final class StatusIcon {
    private let button: NSStatusBarButton
    private let symbolConfig = NSImage.SymbolConfiguration(pointSize: 15, weight: .regular)

    init(button: NSStatusBarButton) {
        self.button = button
    }

    func update(icon: MenuIcon, color: BadgeColor, badged: Bool) {
        let config = badged ? symbolConfig.applying(.init(paletteColors: [color.color])) : symbolConfig
        guard let symbol = NSImage(systemSymbolName: icon.rawValue, accessibilityDescription: "NotBar")?
            .withSymbolConfiguration(config) else { return }
        symbol.isTemplate = !badged
        button.image = symbol
    }
}
