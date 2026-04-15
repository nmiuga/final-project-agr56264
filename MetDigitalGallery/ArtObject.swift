//
//  ArtObject.swift
//  MetDigitalGallery
//
//  Created by Allison Ramirez on 4/1/26.
//
//  PROJECT 2 — Model Layer
//  Codable structs that map directly to the Metropolitan Museum of Art's
//  public Collection API (https://metmuseum.github.io/).
//
//  Two API endpoints are modeled here:
//    1. Search endpoint  → SearchResponse
//       GET /public/collection/v1/search?q={query}&hasImages=true
//       Returns a list of matching object IDs.
//
//    2. Object endpoint  → ArtObject
//       GET /public/collection/v1/objects/{objectID}
//       Returns full metadata for a single artwork.
//

import Foundation

// MARK: - SearchResponse
// Decodes the JSON returned by the /search endpoint.
// Example JSON shape:
//   { "total": 3, "objectIDs": [436535, 436544, 436546] }
struct SearchResponse: Codable {
    let total: Int          // Total number of matching results
    let objectIDs: [Int]?   // Array of object IDs (optional — API returns null when 0 results)
}

// MARK: - ArtObject
// Decodes the JSON returned by the /objects/{id} endpoint.
// Conforms to Identifiable so it can be used directly in SwiftUI List / ForEach.
// All fields use the exact key names from the API so JSONDecoder can map them
// without a custom CodingKeys enum.
struct ArtObject: Codable, Identifiable {

    // --- Identity ---
    let objectID: Int           // Unique identifier for the artwork in the Met collection

    // --- Title & Attribution ---
    let title: String           // Primary title of the artwork
    let artistDisplayName: String   // Artist's name as displayed (may be empty string)
    let artistDisplayBio: String    // Brief artist bio, e.g. "Dutch, 1853–1890"
    let artistNationality: String   // Artist's nationality, e.g. "Dutch"

    // --- Date & Origin ---
    let objectDate: String      // Human-readable date string, e.g. "1889" or "ca. 1650–60"
    let objectBeginDate: Int    // Numeric begin year (used for sorting / filtering)
    let culture: String         // Cultural context, e.g. "French" or "Japanese"
    let period: String          // Art-historical period, e.g. "Edo period (1615–1868)"
    let dynasty: String         // Dynasty if applicable, e.g. "Ming dynasty"

    // --- Classification ---
    let medium: String          // Materials used, e.g. "Oil on canvas"
    let dimensions: String      // Physical size string
    let department: String      // Museum department, e.g. "European Paintings"
    let classification: String  // Object type, e.g. "Paintings", "Drawings", "Photographs"

    // --- Images ---
    let primaryImage: String       // Full-resolution image URL (can be large)
    let primaryImageSmall: String  // Web-sized thumbnail URL (preferred for list rows)

    // --- Links ---
    let objectURL: String       // Canonical page on metmuseum.org

    // --- Flags ---
    let isHighlight: Bool       // True if the Met considers this a highlight piece
    let isPublicDomain: Bool    // True if the image is free to use

    // Identifiable conformance — uses the API's own unique ID
    var id: Int { objectID }

    // Convenience: returns a display-safe artist name
    var displayArtist: String {
        artistDisplayName.isEmpty ? "Unknown Artist" : artistDisplayName
    }

    // Convenience: returns a display-safe title
    var displayTitle: String {
        title.isEmpty ? "Untitled" : title
    }
}
