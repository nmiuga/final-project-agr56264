//
//  ArtworkViewModel.swift
//  MetDigitalGallery
//
//
//  PROJECT 2 — ViewModel Layer
//  ObservableObject class that:
//    • Owns the app's artwork data (published so views re-render automatically)
//    • Makes live API calls to the Met Museum Collection API using URLSession
//    • Exposes a search function that views can trigger
//
//  Architecture pattern: MVVM (Model–View–ViewModel)
//    Model  → ArtObject / SearchResponse  (ArtObject.swift)
//    View   → ArtworkListView / ArtworkDetailView
//    ViewModel → THIS FILE
//

import Foundation
import Combine

// MARK: - ArtworkViewModel

// @Observable alternative could be used in iOS 17+, but ObservableObject
// is used here because it was required by the project spec.
@MainActor
class ArtworkViewModel: ObservableObject {

    // MARK: Published State
    // Any view that uses @ObservedObject or @StateObject with this ViewModel
    // will automatically re-render whenever these values change.

    /// The list of artworks currently displayed in the gallery
    @Published var artworks: [ArtObject] = []

    /// True while network requests are in flight (drives the loading spinner)
    @Published var isLoading: Bool = false

    /// Non-nil when something goes wrong (drives the error banner)
    @Published var errorMessage: String? = nil

    /// The current search term shown in the search bar
    @Published var searchQuery: String = "impressionism"

    // MARK: Private Constants

    /// Base URL for the Met Museum's open-access Collection API (no API key required)
    private let baseURL = "https://collectionapi.metmuseum.org/public/collection/v1"

    /// Cap how many artwork details we fetch per search to keep the UI snappy.
    /// The search endpoint can return thousands of IDs; we only load the first N.
    private let maxResults = 15

    // MARK: - Public API

    /// Entry point called by the List view's .onAppear and the Search button.
    /// Spins up an async Task so the caller doesn't need to be async itself.
    func loadArtworks(query: String? = nil) {
        // Use provided query, or fall back to the current searchQuery
        let term = query ?? searchQuery
        Task {
            await fetchArtworks(query: term)
        }
    }

    // MARK: - Private Networking

    /// Full two-step fetch:
    ///   1. Call /search to get matching object IDs
    ///   2. Call /objects/{id} for each ID to get full artwork details
    ///
    /// All network work happens off the main thread; published property
    /// updates are sent back automatically because @MainActor isolation is
    /// set project-wide (SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor).
    func fetchArtworks(query: String) async {
        // Reset state before each new search
        isLoading = true
        errorMessage = nil
        artworks = []

        do {
            // ── Step 1: Search ───────────────────────────────────────────────
            // Build the search URL with the user's query.
            // hasImages=true filters out objects that have no photos.
            guard let encodedQuery = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
                  let searchURL = URL(string: "\(baseURL)/search?q=\(encodedQuery)&hasImages=true") else {
                errorMessage = "Invalid search query."
                isLoading = false
                return
            }

            // URLSession.shared.data(from:) is the modern async/await version.
            // It suspends this Task while the network request runs, freeing the
            // thread instead of blocking it (unlike the older dataTask callback).
            let (searchData, _) = try await URLSession.shared.data(from: searchURL)

            // Decode JSON into MetSearchResponse using Swift's Codable system.
            // JSONDecoder matches JSON keys to property names automatically.
            let searchResult = try JSONDecoder().decode(SearchResponse.self, from: searchData)

            // Guard against empty results
            guard let objectIDs = searchResult.objectIDs, !objectIDs.isEmpty else {
                errorMessage = "No artworks found for \"\(query)\". Try a different search."
                isLoading = false
                return
            }

            // ── Step 2: Fetch object details ─────────────────────────────────
            // Limit to maxResults to avoid hammering the API or making the user
            // wait too long. The first IDs in the array tend to be the most relevant.
            let limitedIDs = Array(objectIDs.prefix(maxResults))

            // Fetch each artwork sequentially. A production app might use
            // TaskGroup for parallel fetching, but sequential is simpler and
            // polite to the Met's servers.
            var fetchedArtworks: [ArtObject] = []

            for id in limitedIDs {
                guard let objectURL = URL(string: "\(baseURL)/objects/\(id)") else { continue }

                let (objectData, _) = try await URLSession.shared.data(from: objectURL)
                let artwork = try JSONDecoder().decode(ArtObject.self, from: objectData)

                // Only add artworks that have at least a small thumbnail image
                if !artwork.primaryImageSmall.isEmpty {
                    fetchedArtworks.append(artwork)
                }
            }

            // Publish the final result so the List view re-renders
            artworks = fetchedArtworks

        } catch let urlError as URLError {
            // Network-specific errors (no connection, timeout, etc.)
            errorMessage = "Network error: \(urlError.localizedDescription)"
        } catch {
            // JSON decoding errors or anything else unexpected
            errorMessage = "Failed to load artworks: \(error.localizedDescription)"
        }

        isLoading = false
    }
}
