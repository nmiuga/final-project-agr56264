//
//  DominantColor.swift
//  MetDigitalGallery — Inspo Board feature
//
//  A single color extracted from an image. Wraps both a UIColor (for
//  rendering) and a hex string (for sending to Foundation Models, since
//  the LLM is text-only and needs a textual color representation).
//

import UIKit
import SwiftUI

// MARK: - DominantColor

struct DominantColor: Identifiable, Hashable {
    let id = UUID()

    /// Uppercase hex string with leading "#", e.g. "#B34519".
    let hex: String

    /// UIKit color — useful for UIKit rendering if needed.
    let uiColor: UIColor

    /// SwiftUI color — what views actually paint onto swatch tiles.
    var color: Color { Color(uiColor) }
}

// MARK: - UIColor → hex helper

extension UIColor {
    /// Returns a "#RRGGBB" string. Alpha is ignored because the extractor
    /// always returns fully-opaque colors.
    var hexString: String {
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        getRed(&r, green: &g, blue: &b, alpha: &a)
        return String(
            format: "#%02X%02X%02X",
            Int(round(r * 255)),
            Int(round(g * 255)),
            Int(round(b * 255))
        )
    }
}

// MARK: - Hex → Color helper

extension Color {
    /// Initialize a Color from a "#RRGGBB" hex string. Used when
    /// reconstituting saved boards from SwiftData — we persist hex strings
    /// rather than UIColor because Data isn't a natural SwiftData primitive.
    init(hex: String) {
        var trimmed = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.hasPrefix("#") { trimmed.removeFirst() }

        guard trimmed.count == 6, let value = UInt32(trimmed, radix: 16) else {
            self = .gray
            return
        }

        let r = Double((value >> 16) & 0xFF) / 255.0
        let g = Double((value >> 8)  & 0xFF) / 255.0
        let b = Double( value        & 0xFF) / 255.0
        self = Color(red: r, green: g, blue: b)
    }
}
