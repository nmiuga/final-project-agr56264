//
//  ImageLoader.swift
//  MetDigitalGallery — Inspo Board feature
//
//  Tiny async UIImage loader used when the user generates an inspo board
//  from a Met artwork. SwiftUI's AsyncImage renders directly but doesn't
//  hand back a UIImage we can feed into PaletteExtractor — so we do a
//  separate URLSession fetch here.
//
//  No caching for now. TODO: hook up URLCache or NSCache if repeated
//  generations on the same artwork become common.
//

import UIKit

// MARK: - ImageLoader

final class ImageLoader {

    static let shared = ImageLoader()
    private init() {}

    /// Fetch a URL and decode it into a UIImage. Returns nil on any failure
    /// (bad URL, network error, non-image data). Intentionally forgiving —
    /// the caller can show a graceful fallback if this returns nil.
    func load(from urlString: String) async -> UIImage? {
        guard let url = URL(string: urlString), !urlString.isEmpty else { return nil }

        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            // Only accept 2xx responses.
            guard
                let http = response as? HTTPURLResponse,
                (200..<300).contains(http.statusCode)
            else {
                return nil
            }
            return UIImage(data: data)
        } catch {
            return nil
        }
    }
}
