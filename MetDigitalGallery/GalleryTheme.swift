//
//  GalleryTheme.swift
//  MetDigitalGallery
//
//  Created by Allison Ramirez on 4/1/26.
//
//  Design tokens extracted from the Figma design (METAPIPROJECT2).
//  All views import this file's Color and Font extensions instead of
//  repeating raw values throughout the codebase.
//
//  Color palette:
//    terracotta — warm rust/orange-brown  (#B34519 range)
//    cream      — warm off-white app background (#F5EFE4 range)
//    creamDark  — slightly darker, used for active tab pill and placeholders
//
//  Typography:
//    Display → large bold serif (headlines like "Curated Visions")
//    Headline → medium serif (card titles, detail view title)
//    Label    → 10pt semibold, 2pt kerning, uppercase (department tags, section headers)
//

import SwiftUI

// MARK: - Color Palette

extension Color {
    /// Warm rust / terracotta — the brand accent color used for:
    ///   • Department label text ("EUROPEAN PAINTINGS")
    ///   • "Curated Visions" headline on the home feed
    ///   • Date in the detail view
    ///   • "VIEW GALLERY" link on the explore screen
    static let terracotta = Color(red: 0.70, green: 0.27, blue: 0.11)

    /// Warm off-white — primary background for the app shell and cards.
    /// Matches the cream tone visible throughout the Figma screens.
    static let cream = Color(red: 0.97, green: 0.94, blue: 0.89)

    /// Slightly darker cream — used for:
    ///   • The active-tab pill in the custom tab bar
    ///   • Image placeholder tiles while loading
    static let creamDark = Color(red: 0.90, green: 0.86, blue: 0.80)
}

// MARK: - Font Helpers

extension Font {
    /// Large bold serif — "Curated Visions", "Explore the Collection", detail title.
    static func galleryDisplay(_ size: CGFloat) -> Font {
        .system(size: size, weight: .bold, design: .serif)
    }

    /// Medium-weight serif — card titles in the home feed.
    static func galleryHeadline(_ size: CGFloat) -> Font {
        .system(size: size, weight: .semibold, design: .serif)
    }

    /// Tiny semibold sans — used for the uppercase tracked department / section labels.
    /// Apply via the galleryLabelStyle() view modifier below.
    static var galleryLabel: Font {
        .system(size: 10, weight: .semibold)
    }
}

// MARK: - View Modifier

extension View {
    /// Styles text as a "EUROPEAN PAINTINGS"-style label:
    /// uppercase, 2pt letter-spacing, terracotta color.
    ///
    /// Usage:
    ///   Text(artwork.department).galleryLabelStyle()
    func galleryLabelStyle() -> some View {
        self
            .font(.galleryLabel)
            .kerning(2.0)
            .textCase(.uppercase)
            .foregroundStyle(Color.terracotta)
    }
}
