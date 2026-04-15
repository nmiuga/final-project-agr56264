//
//  ArtworkDetailView.swift
//  MetDigitalGallery
//
// 
//
//  PROJECT 2 — View Layer (Detail)
//  Shows all available metadata for a single artwork.
//  Navigated to from ArtworkListView when the user taps a row.
//
//  Features carried over from Projects 0 & 1:
//    • SwiftUI layout fundamentals (VStack, HStack, ScrollView)
//    • SF Symbols for icons
//    • NavigationStack title & back button (managed by parent NavigationStack)
//    • AsyncImage for loading remote artwork photos
//

import SwiftUI

// MARK: - ArtworkDetailView

struct ArtworkDetailView: View {

    // The artwork is passed in from ArtworkListView via NavigationLink.
    // Because ArtObject is a struct (value type), this is a local copy —
    // changes here wouldn't affect the list (which is fine for a read-only detail view).
    let artwork: ArtObject

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {

                // ── Hero Image ────────────────────────────────────────────────
                heroImage

                // ── Metadata ──────────────────────────────────────────────────
                VStack(alignment: .leading, spacing: 20) {

                    // Title + artist header
                    titleSection

                    Divider()

                    // Classification & department badges
                    badgesRow

                    Divider()

                    // Detailed metadata rows
                    detailsSection

                    // Museum URL link (opens in Safari)
                    if let url = URL(string: artwork.objectURL), !artwork.objectURL.isEmpty {
                        Link(destination: url) {
                            HStack {
                                Image(systemName: "arrow.up.right.square")
                                Text("View on metmuseum.org")
                                    .font(.subheadline)
                            }
                            .foregroundStyle(.blue)
                            .padding(.top, 4)
                        }
                    }
                }
                .padding(20)
            }
        }
        .navigationTitle(artwork.displayTitle)
        .navigationBarTitleDisplayMode(.inline)
        // Toolbar badge for highlights
        .toolbar {
            if artwork.isHighlight {
                ToolbarItem(placement: .topBarTrailing) {
                    Label("Highlight", systemImage: "star.fill")
                        .labelStyle(.iconOnly)
                        .foregroundStyle(.yellow)
                }
            }
        }
    }

    // MARK: - Hero Image

    /// Large image at the top of the detail view.
    /// Uses the full-resolution primaryImage when available.
    private var heroImage: some View {
        AsyncImage(url: URL(string: artwork.primaryImage.isEmpty ? artwork.primaryImageSmall : artwork.primaryImage)) { phase in
            switch phase {
            case .empty:
                // Placeholder rectangle while loading
                Rectangle()
                    .fill(Color(.secondarySystemBackground))
                    .overlay(ProgressView())
                    .frame(height: 300)
            case .success(let image):
                image
                    .resizable()
                    .scaledToFit()   // scaledToFit keeps the whole painting visible
                    .frame(maxWidth: .infinity)
            case .failure:
                Rectangle()
                    .fill(Color(.secondarySystemBackground))
                    .overlay(
                        VStack(spacing: 8) {
                            Image(systemName: "photo.slash")
                                .font(.largeTitle)
                                .foregroundStyle(.tertiary)
                            Text("Image unavailable")
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                        }
                    )
                    .frame(height: 250)
            @unknown default:
                EmptyView()
            }
        }
        .background(Color.black)   // Black letterbox behind the image
    }

    // MARK: - Title Section

    private var titleSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(artwork.displayTitle)
                .font(.title2)
                .fontWeight(.bold)
                .fixedSize(horizontal: false, vertical: true) // Allow wrapping

            if !artwork.displayArtist.isEmpty {
                Text(artwork.displayArtist)
                    .font(.title3)
                    .foregroundStyle(.secondary)
            }

            if !artwork.artistDisplayBio.isEmpty {
                Text(artwork.artistDisplayBio)
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
        }
    }

    // MARK: - Badges Row

    /// Pill-shaped tags for department and classification
    private var badgesRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                if !artwork.department.isEmpty {
                    BadgeView(text: artwork.department, color: .blue)
                }
                if !artwork.classification.isEmpty {
                    BadgeView(text: artwork.classification, color: .purple)
                }
                if artwork.isPublicDomain {
                    BadgeView(text: "Public Domain", color: .green)
                }
                if artwork.isHighlight {
                    BadgeView(text: "Met Highlight", color: .orange)
                }
            }
        }
    }

    // MARK: - Details Section

    /// Individual metadata rows — only shows rows that have non-empty values
    private var detailsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            MetadataRow(label: "Date",        value: artwork.objectDate,       icon: "calendar")
            MetadataRow(label: "Medium",      value: artwork.medium,           icon: "paintbrush")
            MetadataRow(label: "Dimensions",  value: artwork.dimensions,       icon: "ruler")
            MetadataRow(label: "Culture",     value: artwork.culture,          icon: "globe.americas")
            MetadataRow(label: "Period",      value: artwork.period,           icon: "hourglass")
            MetadataRow(label: "Dynasty",     value: artwork.dynasty,          icon: "crown")
            MetadataRow(label: "Nationality", value: artwork.artistNationality,icon: "flag")
        }
    }
}

// MARK: - BadgeView

/// A small rounded pill label used for tags
private struct BadgeView: View {
    let text: String
    let color: Color

    var body: some View {
        Text(text)
            .font(.caption)
            .fontWeight(.medium)
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(color.opacity(0.15), in: Capsule())
            .foregroundStyle(color)
    }
}

// MARK: - MetadataRow

/// A labeled row: icon + label on the left, value on the right.
/// Hidden automatically when the value is empty (common in the Met API).
private struct MetadataRow: View {
    let label: String
    let value: String
    let icon: String

    var body: some View {
        // Don't render rows for empty fields — the API returns "" for many optional fields
        if !value.isEmpty {
            HStack(alignment: .top, spacing: 12) {
                // Icon + label
                Label(label, systemImage: icon)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(width: 120, alignment: .leading)

                // Value
                Text(value)
                    .font(.subheadline)
                    .foregroundStyle(.primary)
                    .fixedSize(horizontal: false, vertical: true)

                Spacer(minLength: 0)
            }
        }
    }
}

// MARK: - Preview

#Preview {
    // Sample artwork for canvas preview — uses placeholder values
    NavigationStack {
        ArtworkDetailView(artwork: ArtObject(
            objectID: 436535,
            title: "Wheat Field with Cypresses",
            artistDisplayName: "Vincent van Gogh",
            artistDisplayBio: "Dutch, Zundert 1853–1890 Auvers-sur-Oise",
            artistNationality: "Dutch",
            objectDate: "1889",
            objectBeginDate: 1889,
            culture: "French",
            period: "",
            dynasty: "",
            medium: "Oil on canvas",
            dimensions: "73 × 93.4 cm (28 3/4 × 36 3/4 in.)",
            department: "European Paintings",
            classification: "Paintings",
            primaryImage: "",
            primaryImageSmall: "",
            objectURL: "https://www.metmuseum.org/art/collection/search/436535",
            isHighlight: true,
            isPublicDomain: true
        ))
    }
}
