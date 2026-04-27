//
//  SavedBoard.swift
//  MetDigitalGallery — Inspo Board feature
//
//  SwiftData @Model for a persisted inspo board. Stores everything we need
//  to re-render a board after an app restart, regardless of whether it was
//  generated from a Met artwork or a personal photo.
//
//  Design choice: we flatten the @Generable PaletteBoard into plain String
//  / [String] properties on this model rather than nesting it. Keeps the
//  SwiftData schema simple and lets us query/filter individual fields.
//

import Foundation
import SwiftData

// MARK: - BoardSourceType

/// Where the board's image came from. Stored as a String on SavedBoard
/// because SwiftData handles raw-String enums cleanly across migrations.
enum BoardSourceType: String, Codable {
    case artwork   // pulled from the Met collection via its API
    case photo     // picked from the user's photo library
    case combined  // merged from a Met artwork + a personal photo
}

// MARK: - SavedBoard

@Model
final class SavedBoard {

    // ── Identity ──────────────────────────────────────────────────────
    var id: UUID
    var createdAt: Date

    // ── Source discriminator ──────────────────────────────────────────
    /// Raw value backing BoardSourceType. Use `source` computed property
    /// to access the strongly-typed version.
    var sourceRawValue: String

    // ── Source: Met artwork ───────────────────────────────────────────
    /// Only populated when source == .artwork.
    var metArtworkID: Int?
    var imageURL: String?          // cached so we can re-fetch the image
    var artworkTitle: String?
    var artworkArtist: String?

    // ── Source: Personal photo ────────────────────────────────────────
    /// Only populated when source == .photo. Stored as Data because we
    /// can't reliably re-fetch a photo from PhotosPicker after the fact.
    @Attribute(.externalStorage) var imageData: Data?

    // ── Source: Combined board ────────────────────────────────────────
    /// Only populated when source == .combined.
    /// The personal-photo half of a combined board (Met artwork uses imageURL).
    @Attribute(.externalStorage) var photoImageData: Data?
    /// How many swatches came from the Met artwork side.
    var artworkColorCount: Int?
    /// How many swatches came from the personal photo side.
    var photoColorCount: Int?

    // ── Palette (flattened from @Generable PaletteBoard) ──────────────
    var paletteName: String
    var paletteDescription: String
    var paletteMood: String
    var colorHexes: [String]       // e.g. ["#B34519", "#F5EFE4", ...]
    var colorNames: [String]       // LLM-generated names, same order

    // ── Collection relationship ───────────────────────────────────────
    /// Inverse of BoardCollection.boards. A board can belong to at most
    /// one collection; nil means it's ungrouped.
    var collection: BoardCollection?

    // MARK: - Init

    init(
        id: UUID = UUID(),
        createdAt: Date = Date(),
        source: BoardSourceType,
        metArtworkID: Int? = nil,
        imageURL: String? = nil,
        artworkTitle: String? = nil,
        artworkArtist: String? = nil,
        imageData: Data? = nil,
        photoImageData: Data? = nil,
        artworkColorCount: Int? = nil,
        photoColorCount: Int? = nil,
        palette: PaletteBoard,
        colorHexes: [String],
        collection: BoardCollection? = nil
    ) {
        self.id = id
        self.createdAt = createdAt
        self.sourceRawValue = source.rawValue
        self.metArtworkID = metArtworkID
        self.imageURL = imageURL
        self.artworkTitle = artworkTitle
        self.artworkArtist = artworkArtist
        self.imageData = imageData
        self.photoImageData = photoImageData
        self.artworkColorCount = artworkColorCount
        self.photoColorCount = photoColorCount
        self.paletteName = palette.name
        self.paletteDescription = palette.description
        self.paletteMood = palette.mood
        self.colorHexes = colorHexes
        self.colorNames = palette.colorNames
        self.collection = collection
    }

    // MARK: - Computed

    /// Strongly-typed view over the stored raw value. Falls back to .photo
    /// if somehow an unknown string lands here (shouldn't happen).
    var source: BoardSourceType {
        BoardSourceType(rawValue: sourceRawValue) ?? .photo
    }
}
