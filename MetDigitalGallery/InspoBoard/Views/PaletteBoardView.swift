//
//  PaletteBoardView.swift
//  MetDigitalGallery — Inspo Board feature
//
//  The full inspo-board moodboard. Coordinates extraction + naming +
//  an optional save-to-collection flow. Has two entry points:
//
//    PaletteBoardView(image: uiImage)         ← photo-library flow
//    PaletteBoardView(artwork: artObject)     ← Met artwork flow
//
//  For the artwork init, we kick off an async image fetch so the Met
//  API's primaryImage URL becomes a UIImage before extraction runs.
//

import SwiftUI
import UIKit
import SwiftData

// MARK: - PaletteBoardView

struct PaletteBoardView: View {

    // ── Normalized inputs ─────────────────────────────────────────────
    private let title: String?
    private let artist: String?
    private let metArtworkID: Int?
    private let remoteURLString: String?   // non-nil when we need to fetch
    private let initialImage: UIImage?     // non-nil when ready

    // ── State ─────────────────────────────────────────────────────────
    @State private var image: UIImage?
    @State private var colors: [DominantColor] = []
    @State private var board: PaletteBoard?
    @State private var isLoading = true
    @State private var isSaveSheetPresented = false
    @State private var unavailableReason: String?
    @State private var errorMessage: String?
    @State private var didSave = false

    @Environment(\.modelContext) private var modelContext

    // MARK: - Inits

    /// From a photo the user picked (UIImage already in hand).
    init(
        image: UIImage,
        title: String? = nil,
        artist: String? = nil,
        metArtworkID: Int? = nil
    ) {
        self.initialImage = image
        self.remoteURLString = nil
        self.title = title
        self.artist = artist
        self.metArtworkID = metArtworkID
    }

    /// From a Met artwork (URL-based — loaded asynchronously).
    init(artwork: ArtObject) {
        self.initialImage = nil
        self.remoteURLString = artwork.primaryImage.isEmpty
            ? artwork.primaryImageSmall
            : artwork.primaryImage
        self.title = artwork.displayTitle
        self.artist = artwork.displayArtist
        self.metArtworkID = artwork.objectID
    }

    // MARK: - Body

    var body: some View {
        Group {
            if let reason = unavailableReason {
                AvailabilityGateView(reason: reason)
            } else {
                content
            }
        }
        .task {
            await bootstrap()
        }
        .sheet(isPresented: $isSaveSheetPresented) {
            if let board, let colorHexes = maybeHexes() {
                // Only persist image bytes for personal photos — Met
                // artworks can be re-fetched from imageURL, so saving
                // Data would waste storage (each Met image can be MB).
                let isArtwork = metArtworkID != nil
                SaveBoardSheet(
                    source: isArtwork ? .artwork : .photo,
                    metArtworkID: metArtworkID,
                    imageURL: remoteURLString,
                    imageData: isArtwork ? nil : image.flatMap { $0.jpegData(compressionQuality: 0.85) },
                    photoImageData: nil,
                    artworkColorCount: nil,
                    photoColorCount: nil,
                    artworkTitle: title,
                    artworkArtist: artist,
                    palette: board,
                    colorHexes: colorHexes
                ) {
                    didSave = true
                }
            }
        }
    }

    // MARK: - Main content

    private var content: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {

                // Hero image. Shows placeholder while remote image loads.
                if let image {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: .infinity)
                        .background(Color.black)
                } else {
                    Rectangle()
                        .fill(Color.creamDark)
                        .frame(height: 280)
                        .overlay(ProgressView())
                }

                VStack(alignment: .leading, spacing: 20) {
                    Text("Inspo Board")
                        .galleryLabelStyle()

                    // Palette name (placeholder while LLM runs).
                    if let name = board?.name {
                        Text(name)
                            .font(.galleryDisplay(32))
                    } else {
                        placeholderRect(height: 36, width: 220)
                    }

                    // Mood pill.
                    if let mood = board?.mood {
                        Text(mood.uppercased())
                            .font(.system(size: 10, weight: .semibold))
                            .kerning(1.5)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(Color.terracotta.opacity(0.15), in: Capsule())
                            .foregroundStyle(Color.terracotta)
                    }

                    // Swatches.
                    if !colors.isEmpty {
                        SwatchRowView(colors: colors, names: board?.colorNames)
                    }

                    // Description.
                    if let description = board?.description {
                        Text(description)
                            .font(.galleryHeadline(16))
                            .foregroundStyle(.primary)
                            .fixedSize(horizontal: false, vertical: true)
                    } else if isLoading {
                        VStack(alignment: .leading, spacing: 6) {
                            placeholderRect(height: 14, width: .infinity)
                            placeholderRect(height: 14, width: 200)
                        }
                    }

                    // Error surface.
                    if let errorMessage {
                        Text(errorMessage)
                            .font(.caption)
                            .foregroundStyle(.red)
                    }

                    // Action buttons.
                    HStack(spacing: 12) {
                        // Regenerate — same hexes, new phrasing.
                        Button {
                            Task { await runNamer() }
                        } label: {
                            Label("Regenerate", systemImage: "sparkles")
                                .font(.subheadline.weight(.semibold))
                                .padding(.horizontal, 16)
                                .padding(.vertical, 10)
                                .background(Color.terracotta, in: Capsule())
                                .foregroundStyle(.white)
                        }
                        .disabled(isLoading || colors.isEmpty)

                        // Save — opens SaveBoardSheet.
                        Button {
                            isSaveSheetPresented = true
                        } label: {
                            Label(didSave ? "Saved" : "Save", systemImage: didSave ? "checkmark" : "bookmark")
                                .font(.subheadline.weight(.semibold))
                                .padding(.horizontal, 16)
                                .padding(.vertical, 10)
                                .background(Color.creamDark, in: Capsule())
                                .foregroundStyle(Color.terracotta)
                        }
                        .disabled(board == nil || colors.isEmpty)
                    }
                    .padding(.top, 8)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 40)
            }
        }
        .background(Color.cream.ignoresSafeArea())
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Placeholder helper

    @ViewBuilder
    private func placeholderRect(height: CGFloat, width: CGFloat) -> some View {
        RoundedRectangle(cornerRadius: 3)
            .fill(Color.creamDark)
            .frame(
                maxWidth: width == .infinity ? .infinity : width,
                maxHeight: height
            )
            .frame(height: height)
    }

    // MARK: - Generation flow

    /// Runs once on first appearance. Loads the image if needed, then
    /// extracts palette + runs the namer.
    private func bootstrap() async {
        // Ensure image is loaded.
        if image == nil {
            if let initialImage {
                image = initialImage
            } else if let remoteURLString {
                image = await ImageLoader.shared.load(from: remoteURLString)
            }
        }

        guard let image else {
            isLoading = false
            errorMessage = "Couldn't load the image."
            return
        }

        colors = await PaletteExtractor.shared.extract(from: image, count: 5)
        await runNamer()
    }

    /// Ask Foundation Models to name the extracted palette. Re-runnable
    /// via the Regenerate button.
    private func runNamer() async {
        guard !colors.isEmpty else { return }
        isLoading = true
        defer { isLoading = false }
        errorMessage = nil

        do {
            let hexes = colors.map(\.hex)
            board = try await PaletteNamer.shared.generate(
                hexes: hexes,
                artworkTitle: title,
                artist: artist
            )
        } catch PaletteNamerError.modelUnavailable(let reason) {
            unavailableReason = reason
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    /// Convenience: returns the extracted hex list if we have one to save.
    private func maybeHexes() -> [String]? {
        colors.isEmpty ? nil : colors.map(\.hex)
    }
}
