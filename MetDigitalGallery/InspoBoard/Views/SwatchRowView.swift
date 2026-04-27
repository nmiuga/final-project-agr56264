//
//  SwatchRowView.swift
//  MetDigitalGallery — Inspo Board feature
//
//  Horizontal strip of extracted colors with labels underneath. The
//  labels swap from hex strings (while loading) to LLM-generated names
//  (once PaletteNamer returns).
//

import SwiftUI

// MARK: - SwatchRowView

struct SwatchRowView: View {

    /// The colors to paint.
    let colors: [DominantColor]

    /// LLM-generated names in matching order. Nil → fall back to hex.
    let names: [String]?

    /// Track which swatch was just tapped to show "Copied!" toast.
    @State private var copiedIndex: Int? = nil

    var body: some View {
        HStack(spacing: 6) {
            ForEach(Array(colors.enumerated()), id: \.1.id) { (index, color) in
                VStack(spacing: 6) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 4, style: .continuous)
                            .fill(color.color)
                            .frame(height: 88)
                            .overlay(
                                RoundedRectangle(cornerRadius: 4, style: .continuous)
                                    .stroke(Color.black.opacity(0.06), lineWidth: 0.5)
                            )

                        
                        if copiedIndex == index {
                            RoundedRectangle(cornerRadius: 4, style: .continuous)
                                .fill(Color.black.opacity(0.55))
                                .frame(height: 88)
                                .overlay(
                                    Text("Copied!")
                                        .font(.system(size: 10, weight: .semibold))
                                        .foregroundStyle(.white)
                                )
                        }
                    }
                    .onTapGesture {
                        UIPasteboard.general.string = color.hex
                        withAnimation(.easeIn(duration: 0.1)) { copiedIndex = index }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                            withAnimation { copiedIndex = nil }
                        }
                    }

                    Text(label(for: index, color: color))
                        .font(.system(size: 10, weight: .medium, design: .serif))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.6)
                }
            }
        }
    }

    /// Prefer LLM name; fall back to hex while names aren't ready yet.
    private func label(for index: Int, color: DominantColor) -> String {
        guard let names, index < names.count else { return color.hex }
        return names[index]
    }
}

// MARK: - Static row for saved boards

/// Variant used by the saved-board detail view, which stores hexes + names
/// as plain arrays rather than DominantColor values.
struct StaticSwatchRowView: View {
    let hexes: [String]
    let names: [String]

    var body: some View {
        HStack(spacing: 6) {
            ForEach(Array(hexes.enumerated()), id: \.offset) { index, hex in
                VStack(spacing: 6) {
                    RoundedRectangle(cornerRadius: 4, style: .continuous)
                        .fill(Color(hex: hex))
                        .frame(height: 88)
                        .overlay(
                            RoundedRectangle(cornerRadius: 4, style: .continuous)
                                .stroke(Color.black.opacity(0.06), lineWidth: 0.5)
                        )

                    Text(index < names.count ? names[index] : hex)
                        .font(.system(size: 10, weight: .medium, design: .serif))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.6)
                }
            }
        }
    }
}

