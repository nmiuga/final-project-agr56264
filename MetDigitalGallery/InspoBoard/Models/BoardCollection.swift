//
//  BoardCollection.swift
//  MetDigitalGallery — Inspo Board feature
//
//  SwiftData @Model for a user-named group of SavedBoards. The Profile
//  tab lists these; tapping one opens a grid of the boards inside.
//
//  Examples a user might create: "Autumn Inspirations", "Moody Portraits",
//  "Rothko Studies", "Colors of Home".
//

import Foundation
import SwiftData

// MARK: - BoardCollection

@Model
final class BoardCollection {

    // ── Identity ──────────────────────────────────────────────────────
    var id: UUID
    var createdAt: Date

    /// User-facing name. Editable in the UI.
    var name: String

    /// Optional one-line description / tagline for the collection.
    var subtitle: String?

    // ── Boards ────────────────────────────────────────────────────────
    /// Inverse of SavedBoard.collection. `.nullify` delete rule means if
    /// the user deletes a collection the boards survive as "ungrouped"
    /// rather than being silently destroyed.
    @Relationship(deleteRule: .nullify, inverse: \SavedBoard.collection)
    var boards: [SavedBoard] = []

    // MARK: - Init

    init(
        id: UUID = UUID(),
        createdAt: Date = Date(),
        name: String,
        subtitle: String? = nil
    ) {
        self.id = id
        self.createdAt = createdAt
        self.name = name
        self.subtitle = subtitle
    }

    // MARK: - Computed

    /// Count shown on collection cards. Stable across UI re-renders.
    var boardCount: Int { boards.count }

    /// Up to 4 hex strings pulled from the most recent board, used for
    /// the little 4-tile preview on a collection card. Returns an empty
    /// array if the collection has no boards yet.
    var previewHexes: [String] {
        let latest = boards.sorted { $0.createdAt > $1.createdAt }.first
        let hexes = latest?.colorHexes ?? []
        return Array(hexes.prefix(4))
    }
}
