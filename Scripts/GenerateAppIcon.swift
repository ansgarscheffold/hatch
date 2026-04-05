import AppKit

// Sollte visuell zu HatchApp.makeColoredDockIconFromMenuBarSymbol() passen (Tür-Symbol, Orange + Schiefer).

private let menuBarSystemImageName = "door.left.hand.open"

private func makeDockStyleIcon(pixelSize: CGFloat) -> NSImage? {
    guard let symbol = NSImage(systemSymbolName: menuBarSystemImageName, accessibilityDescription: "Hatch") else {
        return nil
    }

    let canvas = NSSize(width: pixelSize, height: pixelSize)
    let pointSize = pixelSize * 0.52

    let orange = NSColor(srgbRed: 244 / 255, green: 154 / 255, blue: 67 / 255, alpha: 1)
    let slate = NSColor(srgbRed: 92 / 255, green: 119 / 255, blue: 130 / 255, alpha: 1)

    let weightCfg = NSImage.SymbolConfiguration(pointSize: pointSize, weight: .medium)
    let paletteCfg = NSImage.SymbolConfiguration(paletteColors: [orange, slate])
    let combined = weightCfg.applying(paletteCfg)
    guard let configured = symbol.withSymbolConfiguration(combined) else { return nil }

    let image = NSImage(size: canvas, flipped: false) { bounds in
        NSColor.clear.set()
        NSBezierPath(rect: bounds).fill()

        let repSize = configured.size
        let maxW = bounds.width * 0.78
        let maxH = bounds.height * 0.78
        let scale = min(maxW / max(repSize.width, 1), maxH / max(repSize.height, 1))
        let dw = repSize.width * scale
        let dh = repSize.height * scale
        let dx = bounds.midX - dw / 2
        let dy = bounds.midY - dh / 2
        let drawRect = NSRect(x: dx, y: dy, width: dw, height: dh)

        NSGraphicsContext.current?.imageInterpolation = .high
        configured.draw(
            in: drawRect,
            from: NSRect(origin: .zero, size: repSize),
            operation: .sourceOver,
            fraction: 1.0
        )
        return true
    }
    image.isTemplate = false
    return image
}

private func savePNG(_ image: NSImage, path: String) throws {
    guard let tiff = image.tiffRepresentation,
          let bitmap = NSBitmapImageRep(data: tiff) else {
        throw NSError(domain: "GenerateAppIcon", code: 1, userInfo: [NSLocalizedDescriptionKey: "tiff"])
    }
    guard let data = bitmap.representation(using: .png, properties: [:]) else {
        throw NSError(domain: "GenerateAppIcon", code: 2, userInfo: [NSLocalizedDescriptionKey: "png"])
    }
    try data.write(to: URL(fileURLWithPath: path))
}

guard CommandLine.arguments.count >= 2 else {
    FileHandle.standardError.write(Data("usage: GenerateAppIcon <out.png>\n".utf8))
    exit(64)
}

autoreleasepool {
    _ = NSApplication.shared
    NSApplication.shared.setActivationPolicy(.prohibited)

    let outPath = CommandLine.arguments[1]
    guard let image = makeDockStyleIcon(pixelSize: 1024) else {
        FileHandle.standardError.write(Data("failed to render symbol\n".utf8))
        exit(1)
    }
    do {
        try savePNG(image, path: outPath)
    } catch {
        FileHandle.standardError.write(Data("\(error)\n".utf8))
        exit(1)
    }
}
